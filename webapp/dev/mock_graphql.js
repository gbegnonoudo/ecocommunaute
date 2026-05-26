// Mock GraphQL pour EcoCommunauté Web
// Implémente le schéma de webservices/GraphQL_schema.md (sous-ensemble)
// Lancer : node mock_graphql.js
// Port par défaut : 4000 (override avec MOCK_GRAPHQL_PORT)

const http = require('http');

const PORT = process.env.MOCK_GRAPHQL_PORT || 4000;

const data = {
  periodeEnCours: {
    id: 'per-T2-2026',
    trimestre: 'T2 2026',
    statut: 'Ouvert',
    dateDebut: '2026-04-01',
    dateFin: '2026-06-30',
    totalRecettesFCFA: 1250000,
    totalDepensesFCFA: 980000,
    totalRecettesEUR: 1905.74,
    totalDepensesEUR: 1494.06,
    nbOperations: 47
  },
  soldeQuotidien: Array.from({ length: 90 }, (_, i) => ({
    date: new Date(Date.now() - (89 - i) * 86400000).toISOString().slice(0, 10),
    solde: 500000 + Math.round((Math.random() - 0.5) * 200000) + i * 5000
  })),
  dernieresOperations: [
    { id: 'op-001', dateOperation: '2026-05-26', libelle: 'Achat carburant', montantFCFA: 125000, typeOperation: 'Dépense', compte: { numCompte: '5300', libelle: 'Transport' } },
    { id: 'op-002', dateOperation: '2026-05-25', libelle: 'Don famille X', montantFCFA: 50000, typeOperation: 'Recette', compte: { numCompte: '7000', libelle: 'Dons' } },
    { id: 'op-003', dateOperation: '2026-05-24', libelle: 'Loyer mai', montantFCFA: 200000, typeOperation: 'Dépense', compte: { numCompte: '6100', libelle: 'Locations' } }
  ],
  alertes: [
    { niveau: 'warning', message: 'Période à soumettre avant le 15 juillet', lien: '/periodes/per-T2-2026' },
    { niveau: 'info', message: 'Taux de change mis à jour', lien: '/taux' }
  ]
};

// Résolveur très simple : ne supporte que la query DashboardCommunaute
function resolve(query, variables) {
  if (/periodeEnCours/.test(query)) {
    return {
      data: {
        periodeEnCours: data.periodeEnCours,
        soldeQuotidien: /soldeQuotidien/.test(query) ? data.soldeQuotidien : undefined,
        dernieresOperations: /dernieresOperations/.test(query) ? data.dernieresOperations : undefined,
        alertes: /alertes/.test(query) ? data.alertes : undefined
      }
    };
  }
  return { errors: [{ message: 'Query not mocked' }] };
}

const server = http.createServer((req, res) => {
  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type'
  };

  if (req.method === 'OPTIONS') {
    res.writeHead(204, headers);
    return res.end();
  }

  if (req.method !== 'POST' || req.url !== '/api/graphql') {
    res.writeHead(404, headers);
    return res.end(JSON.stringify({ errors: [{ message: 'POST /api/graphql expected' }] }));
  }

  let body = '';
  req.on('data', chunk => body += chunk);
  req.on('end', () => {
    try {
      const { query, variables } = JSON.parse(body);
      console.log(`[${new Date().toISOString()}] GraphQL query received (${query.length} chars)`);
      const result = resolve(query, variables);
      res.writeHead(200, headers);
      res.end(JSON.stringify(result, null, 2));
    } catch (e) {
      res.writeHead(400, headers);
      res.end(JSON.stringify({ errors: [{ message: e.message }] }));
    }
  });
});

server.listen(PORT, () => {
  console.log(`Mock GraphQL EcoCommunauté listening on http://localhost:${PORT}/api/graphql`);
  console.log('Query supportée : DashboardCommunaute (cf PAGE_TableauDeBord.md)');
});
