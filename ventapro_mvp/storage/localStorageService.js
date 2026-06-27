(function (window) {
  "use strict";

  const CURRENT_PROJECT_KEY = "ventapro.currentProject";
  const PROJECTS_KEY = "ventapro.projects";
  const QUOTE_COUNTER_KEY = "ventapro.quoteCounter";

  function canUseStorage() {
    try {
      return Boolean(window.localStorage);
    } catch (error) {
      console.warn("VENTAPRO: localStorage no esta disponible.", error);
      return false;
    }
  }

  function readJson(key, fallback) {
    if (!canUseStorage()) {
      return fallback;
    }

    try {
      const raw = window.localStorage.getItem(key);
      return raw ? JSON.parse(raw) : fallback;
    } catch (error) {
      console.warn(`VENTAPRO: no se pudo leer localStorage (${key}).`, error);
      return fallback;
    }
  }

  function writeJson(key, value) {
    if (!canUseStorage()) {
      return false;
    }

    try {
      window.localStorage.setItem(key, JSON.stringify(value));
      return true;
    } catch (error) {
      console.warn(`VENTAPRO: no se pudo guardar localStorage (${key}).`, error);
      return false;
    }
  }

  function removeItem(key) {
    if (!canUseStorage()) {
      return false;
    }

    try {
      window.localStorage.removeItem(key);
      return true;
    } catch (error) {
      console.warn(`VENTAPRO: no se pudo limpiar localStorage (${key}).`, error);
      return false;
    }
  }

  function isValidProject(project) {
    return Boolean(
      project &&
      typeof project === "object" &&
      project.id &&
      project.name &&
      project.customer &&
      Array.isArray(project.panels)
    );
  }

  function loadCurrentProject() {
    const project = readJson(CURRENT_PROJECT_KEY, null);
    return isValidProject(project) ? project : null;
  }

  function saveCurrentProject(project) {
    if (!isValidProject(project)) {
      console.warn("VENTAPRO: se evito guardar un proyecto sin estructura valida.", project);
      return false;
    }

    return writeJson(CURRENT_PROJECT_KEY, project);
  }

  function loadProjects() {
    const projects = readJson(PROJECTS_KEY, []);
    return Array.isArray(projects) ? projects.filter(isValidProject) : [];
  }

  function saveProjects(projects) {
    const validProjects = Array.isArray(projects) ? projects.filter(isValidProject) : [];
    return writeJson(PROJECTS_KEY, validProjects);
  }

  function upsertProject(project) {
    if (!isValidProject(project)) {
      return loadProjects();
    }

    const projects = loadProjects();
    const existingIndex = projects.findIndex((item) => item.id === project.id);
    if (existingIndex >= 0) {
      projects[existingIndex] = project;
    } else {
      projects.unshift(project);
    }
    saveProjects(projects);
    saveCurrentProject(project);
    return projects;
  }

  function clearCurrentProject() {
    return removeItem(CURRENT_PROJECT_KEY);
  }

  function getQuoteCounter() {
    const counter = readJson(QUOTE_COUNTER_KEY, {});
    return counter && typeof counter === "object" ? counter : {};
  }

  function saveQuoteCounter(counter) {
    return writeJson(QUOTE_COUNTER_KEY, counter || {});
  }

  function generateQuoteNumber(existingNumber) {
    if (existingNumber) {
      return existingNumber;
    }

    const year = new Date().getFullYear();
    const counter = getQuoteCounter();
    const next = Number(counter[year] || 0) + 1;
    counter[year] = next;
    saveQuoteCounter(counter);
    return `VENTA-${year}-${String(next).padStart(4, "0")}`;
  }

  window.VentaProLocalStorageService = {
    loadCurrentProject,
    saveCurrentProject,
    loadProjects,
    saveProjects,
    upsertProject,
    clearCurrentProject,
    generateQuoteNumber,
    isValidProject,
  };
})(window);
