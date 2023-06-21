# frozen_string_literal: true

require 'test_helper'
require 'mini_api/model_responder_test'

module CustomErrorSerializer
  class DummyRecord < ActiveRecord::Base
    validates :first_name, presence: true
    validates :last_name, presence: true
  end

  class DummyRecordSerializer < ActiveModel::Serializer
    attributes :first_name, :last_name

    class Error < ActiveModel::Serializer
      attributes :dummy

      def dummy
        {
          'first_name' => object.errors[:first_name],
          'last_name' => object.errors[:last_name]
        }
      end
    end
  end

  class DummyRecordsController < ActionController::Base
    include MiniApi

    def create
      dummy_params = { first_name: params[:first_name], last_name: params[:last_name] }

      dummy_record = DummyRecord.new(dummy_params)

      dummy_record.save

      render_json dummy_record
    end
  end

  class CustomErrorSerializerTest < ModelResponderTest
    setup do
      Rails.application.routes.draw do
        namespace :custom_error_serializer do
          post '/dummy', to: 'dummy_records#create'
        end
      end
    end

    test 'should use custom render error when defined' do
      post '/custom_error_serializer/dummy'

      assert_response :unprocessable_entity

      errors = {
        'dummy' => {
          'first_name' => ["can't be blank"],
          'last_name' => ["can't be blank"]
        }
      }

      assert_equal response.parsed_body['errors'], errors

      assert_equal 'Dummy record could not be created.', response.parsed_body['message']
    end

    test 'success should be false' do
      post '/custom_error_serializer/dummy'

      refute response.parsed_body['success']
    end
  end
end
