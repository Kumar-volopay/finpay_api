require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "FinPay API",
        version: "v1",
        description: "FinPay API documentation"
      },
      servers: [
        {
          url: "/",
          description: "Current server"
        }
      ],
      components: {
        securitySchemes: {
          BearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: "JWT"
          }
        }
      },
      paths: {}
    }
  }

  config.openapi_format = :yaml
end
