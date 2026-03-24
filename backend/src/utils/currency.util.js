const toPaise = (rupees) => {
  return Math.round(Number(rupees) * 100);
};

const toRupees = (paise) => {
  return Number(paise) / 100;
};

const formatINR = (amount) => {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    minimumFractionDigits: 0,
    maximumFractionDigits: 2
  }).format(amount);
};

module.exports = { toPaise, toRupees, formatINR };
