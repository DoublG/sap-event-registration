// The site's own texts in its three languages (Dutch informal "je", French "vous",
// as in the Django site). The UI5 components translate their own texts
// (setLanguage), and the CAP services return a dojo's texts in the language
// sent as Accept-Language (CDS `localized`).
import { reactive } from 'vue'
import { setLanguage } from '@ui5/webcomponents-base/dist/config/Language.js'

const messages = {
  nl: {
    appTitle: 'CoderDojo', skip: 'Naar de inhoud', language: 'Taal', signedInAs: 'Ingelogd als', notSignedIn: 'Niet ingelogd',
    navSessions: 'Sessies', navDojos: 'Dojo\'s', navFamily: 'Mijn gezin',
    findDojo: 'Zoek een dojo', searchPlaceholder: 'Naam of gemeente', noDojos: 'Geen dojo\'s gevonden.', ages: 'Leeftijd {min}–{max}',
    upcoming: 'Komende sessies', places: '{n} plaatsen', placesOne: '1 plaats', signUp: 'Inschrijven', signInToSignUp: 'Log in om in te schrijven.',
    whoComes: 'Wie komt er naar {name}?', confirm: 'Inschrijven', cancel: 'Annuleren', close: 'Sluiten',
    gotPlace: '{name} heeft een plaats.', onWaitingList: '{name} staat op de wachtlijst (positie {position}).',
    myChildren: 'Mijn kinderen', noChildren: 'Je hebt nog geen kinderen toegevoegd.', myPlaces: 'Ingeschreven voor',
    noPlaces: 'Nog nergens ingeschreven.', waitingList: 'Wachtlijst', confirmed: 'Bevestigd', cancelPlace: 'Uitschrijven',
    cancelled: 'De inschrijving is geannuleerd.', loading: 'Laden…', error: 'Er ging iets mis: {message}',
  },
  fr: {
    appTitle: 'CoderDojo', skip: 'Aller au contenu', language: 'Langue', signedInAs: 'Connecté en tant que', notSignedIn: 'Non connecté',
    navSessions: 'Sessions', navDojos: 'Dojos', navFamily: 'Ma famille',
    findDojo: 'Trouver un dojo', searchPlaceholder: 'Nom ou commune', noDojos: 'Aucun dojo trouvé.', ages: '{min}–{max} ans',
    upcoming: 'Prochaines sessions', places: '{n} places', placesOne: '1 place', signUp: 'S\'inscrire', signInToSignUp: 'Connectez-vous pour vous inscrire.',
    whoComes: 'Qui vient à {name} ?', confirm: 'Inscrire', cancel: 'Annuler', close: 'Fermer',
    gotPlace: '{name} a une place.', onWaitingList: '{name} est sur la liste d\'attente (position {position}).',
    myChildren: 'Mes enfants', noChildren: 'Vous n\'avez pas encore ajouté d\'enfant.', myPlaces: 'Inscrit à',
    noPlaces: 'Aucune inscription pour l\'instant.', waitingList: 'Liste d\'attente', confirmed: 'Confirmé', cancelPlace: 'Désinscrire',
    cancelled: 'L\'inscription est annulée.', loading: 'Chargement…', error: 'Une erreur s\'est produite : {message}',
  },
  en: {
    appTitle: 'CoderDojo', skip: 'Skip to content', language: 'Language', signedInAs: 'Signed in as', notSignedIn: 'Not signed in',
    navSessions: 'Sessions', navDojos: 'Dojos', navFamily: 'My family',
    findDojo: 'Find a dojo', searchPlaceholder: 'Name or town', noDojos: 'No dojos found.', ages: 'Ages {min}–{max}',
    upcoming: 'Upcoming sessions', places: '{n} places', placesOne: '1 place', signUp: 'Sign up', signInToSignUp: 'Sign in to sign up.',
    whoComes: 'Who\'s coming to {name}?', confirm: 'Sign up', cancel: 'Cancel', close: 'Close',
    gotPlace: '{name} has a place.', onWaitingList: '{name} is on the waiting list (position {position}).',
    myChildren: 'My children', noChildren: 'You haven\'t added any children yet.', myPlaces: 'Signed up for',
    noPlaces: 'Not signed up for anything yet.', waitingList: 'Waiting list', confirmed: 'Confirmed', cancelPlace: 'Cancel place',
    cancelled: 'The place has been cancelled.', loading: 'Loading…', error: 'Something went wrong: {message}',
  },
}

export const state = reactive({ lang: localStorageGet('lang') || 'nl' })

export function t(key, params = {}) {
  const text = messages[state.lang]?.[key] ?? messages.en[key] ?? key
  return text.replace(/\{(\w+)\}/g, (_, name) => params[name] ?? '')
}

export async function useLanguage(lang) {
  state.lang = lang
  localStorageSet('lang', lang)
  document.documentElement.lang = lang
  await setLanguage(lang)
}

function localStorageGet(key) { try { return localStorage.getItem(key) } catch { return null } }
function localStorageSet(key, value) { try { localStorage.setItem(key, value) } catch { /* private mode */ } }
