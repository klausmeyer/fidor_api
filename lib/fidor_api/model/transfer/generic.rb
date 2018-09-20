module FidorApi
  module Model
    module Transfer
      class Generic < Model::Base
        # TODO: Not all params are part of routing_info :(
        SUPPORTED_ROUTING_TYPES = {
          'SEPA'             => %w[contact_name remote_iban remote_bic bank_name],
          'FOS_P2P_EMAIL'    => %w[email],
          'FOS_P2P_PHONE'    => %w[mobile_phone_number],
          'FOS_P2P_USERNAME' => %w[username],
          'FPS'              => %w[contact_name remote_account_number remote_sort_code]
        }.freeze

        attribute :id,           :string
        attribute :account_id,   :string
        attribute :external_uid, :string
        attribute :amount,       :integer
        attribute :currency,     :string
        attribute :subject,      :string
        attribute :beneficiary,  :json

        attribute_decimal_methods :amount

        def self.resource_name
          'Transfer'
        end

        def beneficiary=(value)
          write_attribute(:beneficiary, value)
          define_methods_for(beneficiary['routing_type'])
        end

        def routing_type
          @beneficiary ||= {}
          @beneficiary.dig('routing_type')
        end

        def routing_type=(type)
          raise Errors::NotSupported unless SUPPORTED_ROUTING_TYPES.key?(type)

          @beneficiary ||= {}
          @beneficiary['routing_type'] = type
          define_methods_for(type)
        end

        def define_methods_for(type) # rubocop:disable Metrics/MethodLength
          SUPPORTED_ROUTING_TYPES[type].each do |name|
            next if respond_to?(name)

            self.class.define_method name do
              @beneficiary ||= {}
              @beneficiary.dig('routing_info', name)
            end

            self.class.define_method "#{name}=" do |value|
              @beneficiary ||= {}
              @beneficiary['routing_info'] ||= {}
              @beneficiary['routing_info'][name] = value
            end
          end
        end

        def parse_errors(body)
          body['errors'].each do |hash|
            hash['field'].sub!('beneficiary.routing_info.', '')
          end
          super(body)
        end
      end
    end
  end
end
