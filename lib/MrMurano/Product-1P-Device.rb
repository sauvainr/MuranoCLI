require 'MrMurano/Product'

module MrMurano
  class Product1PDevice < ProductBase
    include ProductOnePlatformRpcShim

    def initialize
      super
      @uriparts << :proxy
      @uriparts << 'onep:v1'
      @uriparts << :rpc
      @uriparts << :process
      @model_rid = nil
      @sn_rid = nil
    end

    ## Get the internal protocol identifier for a device
    # +sn+:: Identifier for a device
    def sn_rid(sn)
      return @sn_rid unless @sn_rid.nil?
      prd = Product.new()
      found = []

      offset = 0
      loop do
        listing = prd.list(offset)
        break if listing.empty?
        found = listing.select{|item| item[:sn] == sn}
        break unless found.empty?

        offset += 50
      end

      @sn_rid = found.first[:rid]
      @sn_rid
    end

    ## Get information about a device
    # +sn+:: Identifier for a device
    def info(sn)
      do_rpc({:id=>1,
              :procedure=>:info,
              :arguments=>[sn_rid(sn), {}]
      }, sn_rid(sn))
    end

    ## List resources on a device
    # +sn+:: Identifier for a device
    def list(sn)
      data = info(sn)
      dt = {}
      data[:aliases].each{|k,v| v.each{|a| dt[a] = k.to_s}}
      dt
    end

    def listing(sn)
      do_rpc({:id=>1,
              :procedure=>:listing,
              :arguments=>[sn_rid(sn), [:dataport], {}]
      }, sn_rid(sn))
    end

    ## Read the last value for resources on a device
    # +sn+:: Identifier for a device
    # +aliases+:: Array of resource names
    def read(sn, aliases)
      aliases = [aliases] unless aliases.kind_of? Array
      calls = aliases.map do |a|
        {
         :procedure=>:read,
         :arguments=>[ {:alias=>a}, {} ]
        }
      end
      do_mrpc(calls, sn_rid(sn)).map{|i| i[:result].first[1]}
    end

    ## Get a tree of info for a device and its resources.
    # +sn+:: Identifier for a device
    def twee(sn)
      inf = info(sn)

      info_calls = inf[:aliases].keys.map do |rid|
        {:procedure=>:info, :arguments=>[rid, {}]}
      end

      limitkeys = [:basic, :description, :usage, :children, :storage]

      isubs = do_mrpc(info_calls, sn_rid(sn))
      inf[:children] = isubs.map{|i| i[:result].select{|k,v| limitkeys.include? k} }

      inf.select!{|k,v| limitkeys.include? k }
      inf
    end

  end

end

#  vim: set ai et sw=2 ts=2 :
