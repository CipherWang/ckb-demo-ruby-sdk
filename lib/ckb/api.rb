require_relative 'utils'

require 'json'
require 'net/http'
require 'uri'
require 'sha3'

module Ckb
  URL = "http://localhost:3030"

  class Api
    attr_reader :uri

    def initialize(host: URL)
      @uri = URI(host)
    end

    def rpc_request(method, params: nil)
      response = Net::HTTP.post(
        uri,
        "{\"id\": 1, \"jsonrpc\": \"2.0\", \"method\": \"#{method}\", \"params\": #{params.to_json}}",
        "Content-Type" => "application/json")
      result = JSON.parse(response.body, symbolize_names: true)
      if result[:error]
        raise "jsonrpc error: #{result[:error]}"
      end
      result
    end

    # Returns a default secp256k1-sha3 input unlock contract included in CKB
    def get_system_redeem_script_outpoint
      OpenStruct.new(hash_value: Ckb::Utils.hex_to_bin(genesis_block[:transactions][0][:hash]),
                     index: 0)
    end

    def verify_cell_hash
      SHA3::Digest::SHA256.digest(genesis_block[:transactions][0][:transaction][:outputs][0][:data].pack("c*"))
    end

    def genesis_block
      @__genesis_block ||= get_block(get_block_hash(0))
    end

    def get_block_hash(block_number)
      rpc_request("get_block_hash", params: [block_number])[:result]
    end

    def get_block(block_hash_hex)
      rpc_request("get_block", params: [block_hash_hex])[:result]
    end

    def get_tip_number
      rpc_request("get_tip_header")[:result][:raw][:number]
    end

    def get_cells_by_type_hash(hash_hex, from, to)
      params = [hash_hex, from, to]
      rpc_request("get_cells_by_type_hash", params: params)[:result]
    end

    def get_transaction(tx_hash_hex)
      rpc_request("get_transaction", params: [tx_hash_hex])[:result]
    end

    def send_transaction(transaction)
      rpc_request("send_transaction", params: [transaction])[:result]
    end
  end
end
