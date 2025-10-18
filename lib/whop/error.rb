module Whop
  class Error < StandardError; end

  # Network and timeout errors
  class APIConnectionError < Error
    attr_reader :cause
    def initialize(message = "API connection error", cause: nil)
      super(message)
      @cause = cause
    end
  end

  class APITimeoutError < Error
    attr_reader :cause
    def initialize(message = "API request timed out", cause: nil)
      super(message)
      @cause = cause
    end
  end

  # HTTP status-based errors
  class APIStatusError < Error
    attr_reader :status, :body
    def initialize(status, message = nil, body: nil)
      super(message || "HTTP #{status}")
      @status = status.to_i
      @body = body
    end
  end

  class BadRequestError < APIStatusError; end       # 400
  class AuthenticationError < APIStatusError; end   # 401
  class PermissionDeniedError < APIStatusError; end # 403
  class NotFoundError < APIStatusError; end         # 404
  class ConflictError < APIStatusError; end         # 409
  class UnprocessableEntityError < APIStatusError; end # 422
  class RateLimitError < APIStatusError; end        # 429
  class InternalServerError < APIStatusError; end   # >= 500
end


