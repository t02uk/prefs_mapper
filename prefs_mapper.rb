require 'rexml/document'
require 'erb'


class PrefsMapper

  DEFAULT_FILE = "#{File.expand_path(File.dirname(__FILE__))}/default.conf"
  TEMPLATE_FILE_NAME = "templ.scala"

  def initialize(source)
    @xml_source = source
  end

  def confirm()

    # load default setting
    defaultSetting = {}
    if File.exist?(DEFAULT_FILE)
      defaultSetting = eval(File.read(DEFAULT_FILE))
    else 
      defaultSetting = {
        namespace: "",
        file_name: ""
      }
    end

    print "input loader namespace (#{defaultSetting[:namespace]})> "
    @namespace = STDIN.gets.chomp
    @namespace = defaultSetting[:namespace] if @namespace =~ /^$/
    defaultSetting[:namespace] = @namespace

    print "input loader filename (#{defaultSetting[:file_name]})> "
    @file_name = STDIN.gets.chomp
    @file_name = defaultSetting[:file_name] if @file_name =~ /^$/
    defaultSetting[:file_name] = @file_name

    # save default setting
    File.open(DEFAULT_FILE, 'w') do |f|
      f.puts defaultSetting.inspect
    end

    raise "failed to get loader base name " unless @file_name =~ /^(.+)\.scala/
    @class_name = $1
  end

  class Item
    include Enumerable

    # unused
    def each
      @children.each do |e|
        yield e
      end
    end

    def has_child?
      not @children.empty?
    end

    attr_reader :component, :name, :title, :default, :type, :load_method, :children

    def initialize(e)
      @component = e.name
      @name = e.attributes['android:key']
      @title = e.attributes['android:title']
      @default = e.attributes['android:defaultValue']
      @type = e.attributes['my:type']

      # inspect type from default value
      unless @type
        if @default
          @type = if @default.downcase == "true" || @default.downcase == "false"
            "Boolean"
          elsif @default =~ /^-?\d*\.\d+(f|F)?$/
            "Float"
          elsif @default =~ /^-?\d+(l)$/
            "Long"
          elsif @default =~ /^-?\d+$/
            "Int"
          else
            "String"
          end
        end
      end
      # default
      @type ||= "String"
      
      # get load_method from type
      @load_method = case @type.downcase
        when "int"
          %Q(getString("#{@name}", "#{@default}").toInt)
        when "long"
          %Q(getString("#{@name}", "#{@default}").toLong)
        when "float"
          %Q(getString("#{@name}", "#{@default}").toFloat)
        when "double"
          %Q(getString("#{@name}", "#{@default}").toDouble)
        when "string"
          %Q(getString("#{@name}", "#{@default}"))
        when "boolean"
          %Q(getBoolean("#{@name}", #{@default}))
        else
          raise "unknown type `#{@type}`"
      end
      if @component == "CheckBoxPreference"
        @type = "Boolean"
      end

      # recursive call myself
      @children = []
      if @component == "PreferenceCategory"
        @children = e.reject { |child|
          child.to_s =~ /^\s*$/
        }.map { |child|
          Item::new(child)
        }.compact
      end
    end
  end

  # parse xml file
  def parse()
    prefs_content = File::new(@xml_source).read
    parsed = REXML::Document.new prefs_content

    @items = parsed.root.reject { |e|
      e.to_s =~ /^\s*$/
    }.map { |e|
      Item::new(e)
    }

    @items = @items.map { |e|
      e.has_child? ? e.children : e
    }.flatten

  end

  # make scala loader file
  def make()
    dist_source = nil
    open("#{File::dirname(__FILE__)}/#{TEMPLATE_FILE_NAME}") do |data|
      dist_source = eval(ERB.new(data.read, nil, '-').src, binding, __FILE__, __LINE__)
    end

    if @xml_source =~ /(^.+\\main\\)/   # mvn style
      base_dir = $1
      dist_dir = @namespace.gsub(/\./, "\\")
      output_folder = "#{base_dir}scala\\#{dist_dir}"
    elsif @xml_source =~ /^(.+\\)res/   # ant style
      base_dir = $1
      dist_dir = @namespace.gsub(/\./, "\\")
      output_folder = "#{base_dir}src\\#{dist_dir}"
    else
      raise "faild to get base directory" 
    end
    output_path = "#{output_folder}\\#{@file_name}"
    Dir::mkdir(output_folder) unless File::exists?(output_folder)


    File::open(output_path, 'w') do |file|
      file.write(dist_source)
    end
    puts "success! output file > #{output_path}"
  end

end

raise "please give me xml file" if ARGV.size < 1

pl = PrefsMapper.new(ARGV[0])
pl.confirm()
pl.parse()
pl.make()
