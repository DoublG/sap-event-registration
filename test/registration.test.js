// The port of events/registrations.py, checked against the same rules as
// events.tests in Django: places, waiting list, cancellation, access.
const cds = require('@sap/cds')
const { test, describe, beforeEach } = require('node:test')
const assert = require('node:assert')

const { GET, POST, axios } = cds.test(__dirname + '/..')

const EVENT = 'e0000000-0000-0000-0000-000000000001'   // open, 1 place
const DRAFT_EVENT = 'e0000000-0000-0000-0000-000000000002'
const NOOR = 'b0000000-0000-0000-0000-000000000001'
const LARS = 'b0000000-0000-0000-0000-000000000002'
const INES = 'b0000000-0000-0000-0000-000000000003'    // someone else's child
const GENT = 'd0000000-0000-0000-0000-000000000001'

const asParent = { auth: { username: 'parent', password: '' } }
const asChampion = { auth: { username: 'champion', password: '' } }
const fail = p => p.then(() => assert.fail('expected an error'), e => e.response)

describe('public service', () => {
  test('lists only active, non-organisation dojos', async () => {
    const { data } = await GET('/public/Dojos?$select=name')
    assert.deepStrictEqual(data.value.map(d => d.name), ['CoderDojo Gent'])
  })

  test('hides draft sessions and sessions of hidden dojos', async () => {
    const { data } = await GET('/public/Events?$select=name')
    assert.deepStrictEqual(data.value.map(e => e.name), ['Saturday session'])
  })

  test('serves a dojo text in the visitor\'s language (localized)', async () => {
    const { data } = await GET(`/public/Dojos(${GENT})?$select=tagline`, { headers: { 'Accept-Language': 'nl' } })
    assert.strictEqual(data.tagline, 'Kom coderen in Gent')
  })
})

describe('family service', () => {
  beforeEach(async () => {
    const { Registrations, RegistrationCancellations } = cds.entities('coderdojo.events')
    await DELETE.from(Registrations)
    await DELETE.from(RegistrationCancellations)
  })

  test('needs a login', async () => {
    const res = await fail(GET('/family/MyNinjas'))
    assert.strictEqual(res.status, 401)
  })

  test('a guardian sees only their own children', async () => {
    const { data } = await GET('/family/MyNinjas?$select=name&$orderby=name', asParent)
    assert.deepStrictEqual(data.value.map(n => n.name), ['Lars', 'Noor'])
  })

  test('first child gets the place, the second goes on the waiting list', async () => {
    const { data } = await POST('/family/signUp', { event: EVENT, ninjas: [NOOR, LARS] }, asParent)
    assert.deepStrictEqual(data.value.map(r => [r.ninja_ID, r.waitingList, r.position]),
      [[NOOR, false, 1], [LARS, true, 2]])
  })

  test('the registration copies the session\'s pathways and sets the home dojo', async () => {
    await POST('/family/signUp', { event: EVENT, ninjas: [NOOR] }, asParent)
    const reg = await SELECT.one.from('coderdojo.events.Registrations', r => { r.ID, r.pathways(p => p.pathway_ID) })
    assert.strictEqual(reg.pathways.length, 1)
    const noor = await SELECT.one.from('coderdojo.accounts.Ninjas', NOOR)
    assert.strictEqual(noor.homeDojo_ID, GENT)
  })

  test('signing up twice is refused', async () => {
    await POST('/family/signUp', { event: EVENT, ninjas: [NOOR] }, asParent)
    const res = await fail(POST('/family/signUp', { event: EVENT, ninjas: [NOOR] }, asParent))
    assert.strictEqual(res.status, 409)
  })

  test('a closed (draft) session is refused', async () => {
    const res = await fail(POST('/family/signUp', { event: DRAFT_EVENT, ninjas: [NOOR] }, asParent))
    assert.strictEqual(res.status, 409)
  })

  test('someone else\'s child is a 404', async () => {
    const res = await fail(POST('/family/signUp', { event: EVENT, ninjas: [INES] }, asParent))
    assert.strictEqual(res.status, 404)
  })

  test('cancelling a confirmed place promotes the first child waiting', async () => {
    const { data } = await POST('/family/signUp', { event: EVENT, ninjas: [NOOR, LARS] }, asParent)
    const noorsPlace = data.value.find(r => r.ninja_ID === NOOR).ID
    await POST('/family/cancel', { registration: noorsPlace }, asParent)
    const left = await SELECT.from('coderdojo.events.Registrations')
    assert.deepStrictEqual(left.map(r => [r.ninja_ID, r.waitingList]), [[LARS, false]])
    const log = await SELECT.from('coderdojo.events.RegistrationCancellations')
    assert.strictEqual(log.length, 1)
    assert.strictEqual(log[0].wasWaitlisted, false)
  })
})

describe('dojo admin service', () => {
  test('a champion sees their own dojo only', async () => {
    const { data } = await GET('/dojo-admin/Dojos?$select=name', asChampion)
    assert.deepStrictEqual(data.value.map(d => d.name), ['CoderDojo Gent'])
  })

  test('a parent has no access', async () => {
    const res = await fail(GET('/dojo-admin/Dojos', asParent))
    assert.strictEqual(res.status, 403)
  })
})
