const TN_DISTRICTS = [
  { name: 'Chennai', nameTamil: 'சென்னை', lat: 13.0827, lng: 80.2707 },
  { name: 'Coimbatore', nameTamil: 'கோயம்புத்தூர்', lat: 11.0168, lng: 76.9558 },
  { name: 'Madurai', nameTamil: 'மதுரை', lat: 9.9252, lng: 78.1198 },
  { name: 'Tiruchirappalli', nameTamil: 'திருச்சிராப்பள்ளி', lat: 10.7905, lng: 78.7047 },
  { name: 'Salem', nameTamil: 'சேலம்', lat: 11.6643, lng: 78.1460 },
  { name: 'Tirunelveli', nameTamil: 'திருநெல்வேலி', lat: 8.7139, lng: 77.7567 },
  { name: 'Erode', nameTamil: 'ஈரோடு', lat: 11.3410, lng: 77.7172 },
  { name: 'Vellore', nameTamil: 'வேலூர்', lat: 12.9165, lng: 79.1325 },
  { name: 'Thanjavur', nameTamil: 'தஞ்சாவூர்', lat: 10.7870, lng: 79.1378 },
  { name: 'Dindigul', nameTamil: 'திண்டுக்கல்', lat: 10.3624, lng: 77.9695 },
  { name: 'Thoothukudi', nameTamil: 'தூத்துக்குடி', lat: 8.7642, lng: 78.1348 },
  { name: 'Tirupur', nameTamil: 'திருப்பூர்', lat: 11.1085, lng: 77.3411 },
  { name: 'Kanchipuram', nameTamil: 'காஞ்சிபுரம்', lat: 12.8342, lng: 79.7036 },
  { name: 'Cuddalore', nameTamil: 'கடலூர்', lat: 11.7480, lng: 79.7714 },
  { name: 'Nagapattinam', nameTamil: 'நாகப்பட்டினம்', lat: 10.7672, lng: 79.8449 },
  { name: 'Villupuram', nameTamil: 'விழுப்புரம்', lat: 11.9401, lng: 79.4861 },
  { name: 'Krishnagiri', nameTamil: 'கிருஷ்ணகிரி', lat: 12.5186, lng: 78.2137 },
  { name: 'Sivaganga', nameTamil: 'சிவகங்கை', lat: 10.4275, lng: 78.4808 },
  { name: 'Ramanathapuram', nameTamil: 'ராமநாதபுரம்', lat: 9.3639, lng: 78.8395 },
  { name: 'Virudhunagar', nameTamil: 'விருதுநகர்', lat: 9.5681, lng: 77.9624 },
  { name: 'Namakkal', nameTamil: 'நாமக்கல்', lat: 11.2189, lng: 78.1674 },
  { name: 'Karur', nameTamil: 'கரூர்', lat: 10.9601, lng: 78.0766 },
  { name: 'Perambalur', nameTamil: 'பெரம்பலூர்', lat: 11.2328, lng: 78.8816 },
  { name: 'Ariyalur', nameTamil: 'அரியலூர்', lat: 11.1400, lng: 79.0786 },
  { name: 'Nilgiris', nameTamil: 'நீலகிரி', lat: 11.4916, lng: 76.7337 },
  { name: 'Dharmapuri', nameTamil: 'தர்மபுரி', lat: 12.1357, lng: 78.1602 },
  { name: 'Theni', nameTamil: 'தேனி', lat: 10.0104, lng: 77.4777 },
  { name: 'Tiruvannamalai', nameTamil: 'திருவண்ணாமலை', lat: 12.2253, lng: 79.0747 },
  { name: 'Pudukkottai', nameTamil: 'புதுக்கோட்டை', lat: 10.3833, lng: 78.8001 },
  { name: 'Chengalpattu', nameTamil: 'செங்கல்பட்டு', lat: 12.6819, lng: 79.9888 },
  { name: 'Kallakurichi', nameTamil: 'கள்ளக்குறிச்சி', lat: 11.7414, lng: 78.9597 },
  { name: 'Ranipet', nameTamil: 'ராணிப்பேட்டை', lat: 12.9224, lng: 79.3330 },
  { name: 'Tenkasi', nameTamil: 'தென்காசி', lat: 8.9604, lng: 77.3152 },
  { name: 'Tirupattur', nameTamil: 'திருப்பத்தூர்', lat: 12.4955, lng: 78.5730 },
  { name: 'Mayiladuthurai', nameTamil: 'மயிலாடுதுறை', lat: 11.1018, lng: 79.6491 },
];

const TN_REGIONAL_HOLIDAYS = [
  { name: 'Pongal', nameTamil: 'பொங்கல்', month: 1, day: 14 },
  { name: 'Thiruvalluvar Day', nameTamil: 'திருவள்ளுவர் தினம்', month: 1, day: 15 },
  { name: 'Uzhavar Thirunal', nameTamil: 'உழவர் திருநாள்', month: 1, day: 16 },
  { name: 'Tamil New Year', nameTamil: 'தமிழ் புத்தாண்டு', month: 4, day: 14 },
  { name: 'May Day', nameTamil: 'உழைப்பாளர் தினம்', month: 5, day: 1 },
  { name: 'MGR Birthday', nameTamil: 'எம்.ஜி.ஆர் பிறந்த நாள்', month: 1, day: 17 },
  { name: 'Periyar Birthday', nameTamil: 'பெரியார் பிறந்த நாள்', month: 9, day: 17 },
];

const TAMIL_MONTHS = [
  'சித்திரை', 'வைகாசி', 'ஆனி', 'ஆடி', 'ஆவணி', 'புரட்டாசி',
  'ஐப்பசி', 'கார்த்திகை', 'மார்கழி', 'தை', 'மாசி', 'பங்குனி'
];

const isValidTNPincode = (pincode) => {
  if (!pincode || typeof pincode !== 'string') return false;
  return /^6\d{5}$/.test(pincode);
};

const getDistrictByPincode = (pincode) => {
  const prefix = pincode?.substring(0, 3);
  const districtMap = {
    '600': 'Chennai', '601': 'Chengalpattu', '602': 'Chengalpattu',
    '603': 'Chengalpattu', '604': 'Villupuram', '605': 'Cuddalore',
    '606': 'Tiruvannamalai', '607': 'Cuddalore', '608': 'Nagapattinam',
    '609': 'Nagapattinam', '610': 'Thanjavur', '611': 'Thanjavur',
    '612': 'Thanjavur', '613': 'Thanjavur', '614': 'Pudukkottai',
    '620': 'Tiruchirappalli', '621': 'Tiruchirappalli', '622': 'Sivaganga',
    '623': 'Ramanathapuram', '624': 'Dindigul', '625': 'Madurai',
    '626': 'Virudhunagar', '627': 'Tirunelveli', '628': 'Thoothukudi',
    '629': 'Tirunelveli', '630': 'Sivaganga', '631': 'Kanchipuram',
    '632': 'Vellore', '633': 'Tiruvannamalai', '634': 'Dharmapuri',
    '635': 'Krishnagiri', '636': 'Salem', '637': 'Namakkal',
    '638': 'Erode', '639': 'Karur', '641': 'Coimbatore',
    '642': 'Coimbatore', '643': 'Nilgiris',
  };
  return districtMap[prefix] || null;
};

module.exports = {
  TN_DISTRICTS,
  TN_REGIONAL_HOLIDAYS,
  TAMIL_MONTHS,
  isValidTNPincode,
  getDistrictByPincode
};
