const { supabaseAdmin } = require('../config/supabase');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');
const logger = require('../utils/logger');

// Category definitions mapped to existing category_ids in the products table
const CATEGORIES = [
  {
    id: '155c1f84-bd95-47db-8767-e748e33cc491',
    name: 'Vegetables',
    name_ta: 'காய்கறிகள்',
    description: 'Fresh vegetables from local farms',
    icon: null,
    image_url: null,
    sort_order: 1,
    is_active: true
  },
  {
    id: '326e0433-5325-4eca-8245-04c664eea797',
    name: 'Fruits',
    name_ta: 'பழங்கள்',
    description: 'Fresh seasonal fruits',
    icon: null,
    image_url: null,
    sort_order: 2,
    is_active: true
  },
  {
    id: '97c8d318-602d-476c-8a34-f5bcb80267c3',
    name: 'Rice & Dals',
    name_ta: 'அரிசி & பருப்பு',
    description: 'Premium rice varieties and dals',
    icon: null,
    image_url: null,
    sort_order: 3,
    is_active: true
  },
  {
    id: 'fc0ba3d1-62c4-4a3a-a95d-3f853cf194b4',
    name: 'Dairy',
    name_ta: 'பால் பொருட்கள்',
    description: 'Fresh milk, curd, paneer and more',
    icon: null,
    image_url: null,
    sort_order: 4,
    is_active: true
  },
  {
    id: 'b6f4a3a6-b192-4cdb-84a7-9e84a90b4f54',
    name: 'Beverages',
    name_ta: 'பானங்கள்',
    description: 'Coffee, tea, and traditional drinks',
    icon: null,
    image_url: null,
    sort_order: 5,
    is_active: true
  },
  {
    id: 'fd51a691-fc53-4279-8d7e-8f2f8f777f7f',
    name: 'Snacks',
    name_ta: 'தின்பண்டங்கள்',
    description: 'Traditional Tamil Nadu snacks',
    icon: null,
    image_url: null,
    sort_order: 6,
    is_active: true
  },
  {
    id: '17c033e0-b8cf-4397-9759-f068730fbd24',
    name: 'Household',
    name_ta: 'வீட்டுப் பொருட்கள்',
    description: 'Cleaning and household essentials',
    icon: null,
    image_url: null,
    sort_order: 7,
    is_active: true
  },
  {
    id: '6ee13a5c-6b51-4724-8d5f-4ee454cd5b15',
    name: 'Personal Care',
    name_ta: 'தனிப்பட்ட பராமரிப்பு',
    description: 'Soaps, shampoos, and personal care',
    icon: null,
    image_url: null,
    sort_order: 8,
    is_active: true
  }
];

const getCategories = async (req, res, next) => {
  try {
    // Return categories with product counts
    const categoriesWithCounts = await Promise.all(
      CATEGORIES.filter(c => c.is_active).map(async (cat) => {
        const { count } = await supabaseAdmin
          .from('products')
          .select('id, vendors!inner(id)', { count: 'exact', head: true })
          .eq('category_id', cat.id)
          .eq('is_available', true)
          .eq('vendors.is_approved', true)
          .eq('vendors.is_active', true);

        return {
          ...cat,
          product_count: count || 0
        };
      })
    );

    return successResponse(res, categoriesWithCounts);
  } catch (err) {
    next(err);
  }
};

const getCategoryById = async (req, res, next) => {
  try {
    const category = CATEGORIES.find(c => c.id === req.params.id);
    if (!category) {
      return errorResponse(res, 'Category not found', 404);
    }

    const { count } = await supabaseAdmin
      .from('products')
      .select('id, vendors!inner(id)', { count: 'exact', head: true })
      .eq('category_id', category.id)
      .eq('is_available', true)
      .eq('vendors.is_approved', true)
      .eq('vendors.is_active', true);

    return successResponse(res, { ...category, product_count: count || 0 });
  } catch (err) {
    next(err);
  }
};

const getCategoryProducts = async (req, res, next) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const from = (page - 1) * limit;
    const to = from + Number(limit) - 1;

    const category = CATEGORIES.find(c => c.id === req.params.id);
    if (!category) {
      return errorResponse(res, 'Category not found', 404);
    }

    const { data, error, count } = await supabaseAdmin
      .from('products')
      .select('*, vendors!inner(shop_name, is_open)', { count: 'exact' })
      .eq('category_id', req.params.id)
      .eq('is_available', true)
      .eq('vendors.is_approved', true)
      .eq('vendors.is_active', true)
      .order('sort_order', { ascending: true })
      .order('name', { ascending: true })
      .range(from, to);

    if (error) {
      return errorResponse(res, 'Failed to fetch products', 400);
    }

    return paginatedResponse(res, data || [], count || 0, Number(page), Number(limit));
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getCategories,
  getCategoryById,
  getCategoryProducts
};
