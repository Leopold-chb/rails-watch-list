// Gestion des modals de bandes-annonces - Arrêter la vidéo quand le modal se ferme
function initializeTrailerModals() {
  const modals = document.querySelectorAll('.modal[id^="trailerModal"]');

  modals.forEach(function(modal) {
    const iframe = modal.querySelector('iframe');

    if (iframe) {
      // Arrêter la vidéo quand le modal se ferme
      modal.addEventListener('hidden.bs.modal', function() {
        if (iframe.src) {
          // Sauvegarder l'URL et la réinitialiser pour arrêter la vidéo
          const currentSrc = iframe.src;
          iframe.src = '';
          // Remettre l'URL après un court délai pour la prochaine ouverture
          setTimeout(function() {
            iframe.src = currentSrc;
          }, 100);
        }
      });
    }
  });
}

// Initialiser au chargement de la page
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeTrailerModals);
} else {
  initializeTrailerModals();
}

// Gérer aussi les événements Turbo
document.addEventListener('turbo:load', initializeTrailerModals);
document.addEventListener('turbo:frame-load', initializeTrailerModals);
