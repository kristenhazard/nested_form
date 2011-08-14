module NestedForm
  module BuilderMixin
    # Adds a link to insert a new associated records. The first argument is the name of the link, the second is the name of the association.
    #
    #   f.link_to_add("Add Task", :tasks)
    #
    # You can pass HTML options in a hash at the end and a block for the content.
    #
    #   <%= f.link_to_add(:tasks, :class => "add_task", :href => new_task_path) do %>
    #     Add Task
    #   <% end %>
    #
    # See the README for more details on where to call this method.
    def link_to_add(*args, &block)
      options = args.extract_options!.symbolize_keys
      association = args.pop
      options[:class] = [options[:class], "add_nested_fields"].compact.join(" ")
      options["data-association"] = association
      options["data-collection"] = @@collection_id if @collection_tag
      args << (options.delete(:href) || "javascript:void(0)")
      args << options
      @fields ||= {}
      @template.after_nested_form(association) do
        model_object = object.class.reflect_on_association(association).klass.new
        blueprint_tag = case @fields_tag.try(:to_sym)
                        when :tr then :table
                        when :li then :ol
                        else :div
                        end
        output = @template.content_tag blueprint_tag, :id => "#{association}_fields_blueprint", :style => 'display: none' do
          fields_for(association, model_object, :child_index => "new_#{association}", &@fields[association])
        end
      end
      @template.link_to(*args, &block)
    end

    # Adds a link to remove the associated record. The first argment is the name of the link.
    #
    #   f.link_to_remove("Remove Task")
    #
    # You can pass HTML options in a hash at the end and a block for the content.
    #
    #   <%= f.link_to_remove(:class => "remove_task", :href => "#") do %>
    #     Remove Task
    #   <% end %>
    #
    # See the README for more details on where to call this method.
    def link_to_remove(*args, &block)
      options = args.extract_options!.symbolize_keys
      options[:class] = [options[:class], "remove_nested_fields"].compact.join(" ")
      args << (options.delete(:href) || "javascript:void(0)")
      args << options
      hidden_field(:_destroy) + @template.link_to(*args, &block)
    end

    def fields_for(record_or_name_or_array, *args, &block)
      options = args.extract_options!.symbolize_keys
      @collection_tag = options.delete(:collection_tag)
      @fields_tag ||= options.delete(:fields_tag) || :div
      @@collection_id ||= 0 if @collection_tag
      args << options
      output = super(record_or_name_or_array, *args, &block)
      if @collection_tag
        @template.content_tag @collection_tag, output, :id => "collection#{@@collection_id += 1}"
      else
        output
      end
    end

    def fields_for_with_nested_attributes(association_name, *args)
      # TODO Test this better
      block = args.pop || Proc.new { |fields| @template.render(:partial => "#{association_name.to_s.singularize}_fields", :locals => {:f => fields}) }
      @fields ||= {}
      @fields[association_name] = block
      super(association_name, *(args << block))
    end

    def fields_for_nested_model(name, object, options, block)
      @template.content_tag @fields_tag, :class => "#{@template.dom_class(object)} fields" do
        super
      end
    end
  end
end
