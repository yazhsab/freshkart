const templates = {
  order_placed: {
    en: { title: 'Order Placed!', body: 'Your order #{orderNumber} has been placed successfully.' },
    ta: { title: 'ஆர்டர் பதிவாகியது!', body: 'உங்கள் ஆர்டர் #{orderNumber} வெற்றிகரமாக பதிவாகியது.' }
  },
  order_confirmed: {
    en: { title: 'Order Confirmed', body: 'Your order #{orderNumber} has been confirmed by the vendor.' },
    ta: { title: 'ஆர்டர் உறுதிப்படுத்தப்பட்டது', body: 'உங்கள் ஆர்டர் #{orderNumber} கடைக்காரரால் உறுதிப்படுத்தப்பட்டது.' }
  },
  order_packing: {
    en: { title: 'Order Being Packed', body: 'Your order #{orderNumber} is being packed.' },
    ta: { title: 'ஆர்டர் பேக் செய்யப்படுகிறது', body: 'உங்கள் ஆர்டர் #{orderNumber} பேக் செய்யப்படுகிறது.' }
  },
  order_ready: {
    en: { title: 'Order Ready', body: 'Your order #{orderNumber} is ready for pickup.' },
    ta: { title: 'ஆர்டர் தயார்', body: 'உங்கள் ஆர்டர் #{orderNumber} எடுக்க தயாராக உள்ளது.' }
  },
  order_picked_up: {
    en: { title: 'Out for Delivery', body: 'Your order #{orderNumber} is on its way!' },
    ta: { title: 'டெலிவரிக்கு புறப்பட்டது', body: 'உங்கள் ஆர்டர் #{orderNumber} வரும் வழியில் உள்ளது!' }
  },
  order_delivered: {
    en: { title: 'Order Delivered!', body: 'Your order #{orderNumber} has been delivered. Enjoy!' },
    ta: { title: 'ஆர்டர் டெலிவரி ஆகிவிட்டது!', body: 'உங்கள் ஆர்டர் #{orderNumber} டெலிவரி செய்யப்பட்டது. நன்றி!' }
  },
  order_cancelled: {
    en: { title: 'Order Cancelled', body: 'Your order #{orderNumber} has been cancelled.' },
    ta: { title: 'ஆர்டர் ரத்து செய்யப்பட்டது', body: 'உங்கள் ஆர்டர் #{orderNumber} ரத்து செய்யப்பட்டது.' }
  },
  new_order_vendor: {
    en: { title: 'New Order!', body: 'You have a new order #{orderNumber}. Please confirm.' },
    ta: { title: 'புதிய ஆர்டர்!', body: '#{orderNumber} புதிய ஆர்டர் வந்துள்ளது. உறுதிப்படுத்தவும்.' }
  },
  booking_confirmed: {
    en: { title: 'Booking Confirmed', body: 'Your booking #{bookingNumber} is confirmed for {date}.' },
    ta: { title: 'முன்பதிவு உறுதிப்படுத்தப்பட்டது', body: '#{bookingNumber} முன்பதிவு {date} தேதிக்கு உறுதிப்படுத்தப்பட்டது.' }
  },
  booking_completed: {
    en: { title: 'Service Completed', body: 'Your booking #{bookingNumber} service is completed.' },
    ta: { title: 'சேவை நிறைவடைந்தது', body: '#{bookingNumber} சேவை நிறைவடைந்தது.' }
  },
  wallet_credit: {
    en: { title: 'Wallet Credited', body: '₹{amount} has been added to your wallet. Balance: ₹{balance}' },
    ta: { title: 'வாலட் வரவு', body: '₹{amount} உங்கள் வாலட்டில் சேர்க்கப்பட்டது. இருப்பு: ₹{balance}' }
  },
  referral_reward: {
    en: { title: 'Referral Reward!', body: 'You earned ₹{amount} for referring a friend!' },
    ta: { title: 'பரிந்துரை வெகுமதி!', body: 'நண்பரை பரிந்துரைத்ததற்கு ₹{amount} கிடைத்தது!' }
  },
  loyalty_earned: {
    en: { title: 'Points Earned', body: 'You earned {points} loyalty points! Balance: {balance} points' },
    ta: { title: 'புள்ளிகள் கிடைத்தது', body: '{points} லாயல்டி புள்ளிகள் கிடைத்தது! இருப்பு: {balance}' }
  },
  new_chat_message: {
    en: { title: 'New Message', body: '{senderName}: {message}' },
    ta: { title: 'புதிய செய்தி', body: '{senderName}: {message}' }
  },
  rating_reminder: {
    en: { title: 'Rate your experience', body: 'How was your experience? Please rate your order.' },
    ta: { title: 'மதிப்பிடுங்கள்', body: 'உங்கள் அனுபவம் எப்படி இருந்தது? தயவுசெய்து மதிப்பிடுங்கள்.' }
  }
};

const getTemplate = (key, locale = 'en', variables = {}) => {
  const template = templates[key];
  if (!template) return { title: key, body: '' };

  const localized = template[locale] || template['en'];
  let { title, body } = localized;

  // Replace variables
  for (const [varKey, varValue] of Object.entries(variables)) {
    const placeholder = `{${varKey}}`;
    const hashPlaceholder = `#{${varKey}}`;
    title = title.replace(hashPlaceholder, varValue).replace(placeholder, varValue);
    body = body.replace(hashPlaceholder, varValue).replace(placeholder, varValue);
  }

  return { title, body };
};

module.exports = { getTemplate, templates };
