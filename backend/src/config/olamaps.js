const axios = require('axios');

const olaApi = axios.create({
  baseURL: 'https://api.olamaps.io',
  params: { api_key: process.env.OLA_MAPS_API_KEY },
  timeout: 10000
});

module.exports = { olaApi };
