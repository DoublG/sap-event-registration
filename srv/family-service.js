// events/registrations.py, ported: sign_up and cancel.
//
// Django locks the session's row (SELECT ... FOR UPDATE) so two families
// can't take the last place or the same waiting-list position. CAP does the
// same with SELECT.forUpdate() inside the request's transaction; on SQLite
// (development) the whole database is locked per write transaction anyway.
const cds = require('@sap/cds')

module.exports = class FamilyService extends cds.ApplicationService {
  init() {
    const { Events, Registrations, RegistrationCancellations, EventPathways } = cds.entities('coderdojo.events')
    const { Ninjas, Guardianships } = cds.entities('coderdojo.accounts')
    const { Dojos } = cds.entities('coderdojo.dojos')
    const { MyRegistrations } = this.entities

    /** The account behind the logged-in user (the IdP passes it as an attribute). */
    const accountOf = req => {
      const account = req.user.attr?.account
      if (!account) req.reject(403, 'NO_ACCOUNT')
      return account
    }

    // Ninja.objects.signable_by(user): only your own children (404, like Django).
    const assertOwnChildren = async (req, ninjaIDs) => {
      const account = accountOf(req)
      const own = await SELECT.from(Guardianships).columns('ninja_ID')
        .where({ guardian_ID: account, ninja_ID: ninjaIDs })
      if (own.length !== new Set(ninjaIDs).size) req.reject(404, 'NINJA_NOT_FOUND')
    }

    this.on('signUp', async req => {
      const { event: eventID, ninjas: ninjaIDs = [] } = req.data
      if (!ninjaIDs.length) req.reject(400, 'NO_CHILDREN_SELECTED')
      await assertOwnChildren(req, ninjaIDs)

      // _lock(): read everything we decide on after taking the lock.
      const event = await SELECT.one.from(Events, eventID).forUpdate()
      if (!event) req.reject(404, 'EVENT_NOT_FOUND')
      if (event.status !== 'open') req.reject(409, 'Registrations for this session are closed.')

      const already = new Set((await SELECT.from(Registrations).columns('ninja_ID')
        .where({ event_ID: eventID, ninja_ID: ninjaIDs })).map(r => r.ninja_ID))
      const newChildren = ninjaIDs.filter(id => !already.has(id))
      if (!newChildren.length)
        req.reject(409, 'The child(ren) you selected are already signed up for this session.')

      const { max } = await SELECT.one.from(Registrations).columns('max(position) as max').where({ event_ID: eventID })
      let position = max ?? 0
      const { count } = await SELECT.one.from(Registrations).columns('count(1) as count')
        .where({ event_ID: eventID, waitingList: false })
      let confirmed = count
      const pathways = await SELECT.from(EventPathways).columns('pathway_ID').where({ event_ID: eventID })
      const dojo = await SELECT.one.from(Dojos, event.dojo_ID).columns('ID', 'kind')

      const created = []
      for (const ninjaID of newChildren) {
        position += 1
        const waitingList = confirmed >= event.places
        const ID = cds.utils.uuid()
        await INSERT.into(Registrations).entries({
          ID, event_ID: eventID, ninja_ID: ninjaID, waitingList, position,
          pathways: pathways.map(p => ({ pathway_ID: p.pathway_ID })), // registration.pathways.set(...)
        })
        // accounts.home_dojo.assign_on_signup: the first sign-up sets the home dojo.
        if (dojo.kind === 'dojo')
          await UPDATE(Ninjas, ninjaID).set({ homeDojo_ID: dojo.ID, memberSince: new Date().toISOString().slice(0, 10) })
            .where({ homeDojo_ID: null })
        if (!waitingList) confirmed += 1
        created.push(ID)
        await this.emit('booked', { registration: ID, waitingList })
      }
      return SELECT.from(MyRegistrations).where({ ID: created }).orderBy('position')
    })

    this.on('cancel', async req => {
      const account = accountOf(req)
      const registration = await SELECT.one.from(Registrations, req.data.registration)
      if (!registration) return false // cancelled already (a second click)
      await assertOwnChildren(req, [registration.ninja_ID])

      const event = await SELECT.one.from(Events, registration.event_ID).forUpdate()
      const current = await SELECT.one.from(Registrations, registration.ID)
      if (!current) return false

      await INSERT.into(RegistrationCancellations).entries({
        ninja_ID: current.ninja_ID, event_ID: event.ID, wasWaitlisted: current.waitingList,
        signedUpAt: current.createdAt, cancelledBy_ID: account,
      })
      await DELETE.from(Registrations, current.ID)
      if (current.waitingList) return true

      const { count } = await SELECT.one.from(Registrations).columns('count(1) as count')
        .where({ event_ID: event.ID, waitingList: false })
      if (count >= event.places) return true
      const promoted = await SELECT.one.from(Registrations)
        .where({ event_ID: event.ID, waitingList: true }).orderBy('position')
      if (promoted) {
        await UPDATE(Registrations, promoted.ID).set({ waitingList: false })
        await this.emit('waitlistPromoted', { registration: promoted.ID })
      }
      return true
    })

    return super.init()
  }
}
