const successResponse = (res, data, statusCode = 200, message = 'Success') => {
  return res.status(statusCode).json({
    success: true,
    message,
    data
  });
};

const errorResponse = (res, message, statusCode = 500, errors = null) => {
  const body = { success: false, message };
  if (errors) body.errors = errors;
  return res.status(statusCode).json(body);
};

const paginatedResponse = (res, data, total, page, limit) => {
  return res.json({
    success: true,
    data: {
      items: data,
      total,
      page,
      limit,
      has_more: page * limit < total,
      totalPages: Math.ceil(total / limit),
      hasMore: page * limit < total
    }
  });
};

module.exports = { successResponse, errorResponse, paginatedResponse };
