// Mock REST API pour EcoCommunauté Web
// Implémente quelques endpoints clés depuis webservices/REST_API_specification.md
// Lancer : node mock_rest.js
// Port par défaut : 3000 (override avec MOCK_REST_PORT)

const http = require('http');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

const PORT = process.env.MOCK_REST_PORT || 3000;
const PROTOTYPE_DIR = path.join(__dirname, 'prototype');

// Données de démo
const periodes = [
  {
    id: 'per-T2-2026',
    trimestre: 'T2 2026',
    statut: 'Ouvert',
    dateDebut: '2026-04-01',
    dateFin: '2026-06-30',
    totaux: {
      recettesFCFA: 1250000,
      depensesFCFA: 980000,
      recettesEUR: 1905.74,
      depensesEUR: 1494.06,
      nbOperations: 47
    }
  }
];

const operations = [
  { id: 'op-001', dateOperation: '2026-05-26', numCompte: '5300', libelle: 'Achat carburant', typeOperation: 'Dépense', montantFCFA: 125000, montantEUR: 190.68, tauxApplique: 655.957, idPeriode: 'per-T2-2026' },
  { id: 'op-002', dateOperation: '2026-05-25', numCompte: '7000', libelle: 'Don famille X', typeOperation: 'Recette', montantFCFA: 50000, montantEUR: 76.22, tauxApplique: 655.957, idPeriode: 'per-T2-2026' },
  { id: 'op-003', dateOperation: '2026-05-24', numCompte: '6100', libelle: 'Loyer mai', typeOperation: 'Dépense', montantFCFA: 200000, montantEUR: 304.90, tauxApplique: 655.957, idPeriode: 'per-T2-2026' }
];

function send(res, status, body) {
  res.writeHead(status, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type'
  });
  res.end(JSON.stringify(body, null, 2));
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const method = req.method;

  console.log(`[${new Date().toISOString()}] ${method} ${url.pathname}`);

  if (method === 'OPTIONS') return send(res, 204, null);

  // === Static : prototype HTML ===
  if (method === 'GET' && (url.pathname === '/' || url.pathname === '/index.html')) {
    const html = fs.readFileSync(path.join(PROTOTYPE_DIR, 'index.html'), 'utf-8');
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    return res.end(html);
  }

  // POST /auth/login
  if (method === 'POST' && url.pathname === '/auth/login') {
    return send(res, 200, {
      access_token: 'mock-jwt-' + Date.now(),
      refresh_token: 'mock-refresh-' + Date.now(),
      token_type: 'Bearer',
      expires_in: 3600,
      profil: 'COMMUNAUTAIRE',
      requires_2fa: false
    });
  }

  // GET /periodes/courante
  if (method === 'GET' && url.pathname === '/periodes/courante') {
    return send(res, 200, periodes[0]);
  }

  // GET /operations
  if (method === 'GET' && url.pathname === '/operations') {
    const periode = url.searchParams.get('periode');
    const page = parseInt(url.searchParams.get('page') || '1', 10);
    const limit = parseInt(url.searchParams.get('limit') || '50', 10);
    const filtered = periode ? operations.filter(o => o.idPeriode === periode) : operations;
    return send(res, 200, {
      items: filtered.slice((page - 1) * limit, page * limit),
      page,
      limit,
      total: filtered.length
    });
  }

  // POST /operations
  if (method === 'POST' && url.pathname === '/operations') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      const newOp = { id: 'op-' + Date.now(), ...JSON.parse(body || '{}') };
      operations.push(newOp);
      send(res, 201, newOp);
    });
    return;
  }

  // POST /periodes/:id/soumettre
  if (method === 'POST' && /^\/periodes\/[^/]+\/soumettre$/.test(url.pathname)) {
    return send(res, 200, { succes: true, message: 'Période soumise' });
  }

  // GET /taux/courant
  if (method === 'GET' && url.pathname === '/taux/courant') {
    return send(res, 200, { id: 'taux-courant', dateTaux: '2026-05-27', tauxEURFCFA: 655.957, source: 'BCEAO' });
  }

  // 404
  send(res, 404, {
    error: { code: 'NOT_FOUND', message: `Route ${method} ${url.pathname} not mocked` }
  });
});

server.listen(PORT, () => {
  console.log(`Mock REST API EcoCommunauté listening on http://localhost:${PORT}`);
  console.log('Routes mockées :');
  console.log('  POST /auth/login');
  console.log('  GET  /periodes/courante');
  console.log('  GET  /operations?periode=...&page=1&limit=50');
  console.log('  POST /operations');
  console.log('  POST /periodes/:id/soumettre');
  console.log('  GET  /taux/courant');
});
