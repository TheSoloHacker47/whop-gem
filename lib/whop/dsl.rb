module Whop
  module DSL
    class Registry
      attr_reader :resources
      def initialize
        @resources = {}
      end

      def resource(name, &block)
        ns = (@resources[name.to_sym] ||= Namespace.new(name))
        ns.instance_eval(&block) if block
        ns
      end
    end

    class Namespace
      attr_reader :name, :methods
      def initialize(name)
        @name = name.to_sym
        @methods = {}
      end

      def graphql(method_name, operation:, args: [])
        @methods[method_name.to_sym] = { type: :graphql, operation: operation, args: Array(args).map(&:to_sym) }
      end

      def graphql_inline(method_name, operation:, query:, args: [])
        @methods[method_name.to_sym] = {
          type: :graphql_inline,
          operation: operation,
          query: query,
          args: Array(args).map(&:to_sym)
        }
      end

      def rest_get(method_name, path:, args: [], params: [])
        @methods[method_name.to_sym] = { type: :rest_get, path: path, args: Array(args).map(&:to_sym), params: Array(params).map(&:to_sym) }
      end

      def rest_post(method_name, path:, args: [], body: [])
        @methods[method_name.to_sym] = { type: :rest_post, path: path, args: Array(args).map(&:to_sym), body: Array(body).map(&:to_sym) }
      end
    end

    class ClientProxy
      def initialize(client, registry)
        @client = client
        @registry = registry
      end

      def method_missing(name, *args, **kwargs, &block)
        ns = @registry.resources[name.to_sym]
        return super unless ns
        NamespaceProxy.new(@client, ns)
      end

      def respond_to_missing?(name, include_all = false)
        @registry.resources.key?(name.to_sym) || super
      end
    end

    class NamespaceProxy
      def initialize(client, namespace)
        @client = client
        @namespace = namespace
      end

      def method_missing(name, *args, **kwargs, &block)
        spec = @namespace.methods[name.to_sym]
        return super unless spec
        case spec[:type]
        when :graphql
          variables = build_named_args(spec[:args], args, kwargs)
          @client.graphql(spec[:operation], variables)
        when :graphql_inline
          variables = build_named_args(spec[:args], args, kwargs)
          @client.graphql_query(spec[:operation], spec[:query], variables)
        when :rest_get
          path = interpolate_path(spec[:path], build_named_args(spec[:args], args, kwargs))
          query = kwargs.select { |k, _| spec[:params].include?(k.to_sym) }
          @client.get(path, params: query)
        when :rest_post
          path = interpolate_path(spec[:path], build_named_args(spec[:args], args, kwargs))
          body = kwargs.select { |k, _| spec[:body].include?(k.to_sym) }
          @client.post(path, json: body)
        else
          raise Whop::Error, "Unknown DSL method type: #{spec[:type]}"
        end
      end

      def respond_to_missing?(name, include_all = false)
        @namespace.methods.key?(name.to_sym) || super
      end

      private

      def build_named_args(arg_names, args, kwargs)
        return kwargs if kwargs && !kwargs.empty?
        Hash[arg_names.zip(args)]
      end

      def interpolate_path(path, named)
        path.gsub(/:(\w+)/) { |m| named[$1.to_sym] }
      end
    end

    module_function

    def registry
      @registry ||= Registry.new
    end

    def define(&block)
      registry.instance_eval(&block)
    end
  end
end


