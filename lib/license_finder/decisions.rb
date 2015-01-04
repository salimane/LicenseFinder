module LicenseFinder
  class Decisions
    ######
    # READ
    ######

    attr_reader :packages, :whitelisted, :ignored, :ignored_groups, :project_name

    def licenses_of(name)
      @licenses[name]
    end

    def approval_of(name)
      @approvals[name]
    end

    def approved?(name)
      @approvals.has_key?(name)
    end

    def approved_license?(lic)
      @whitelisted.include?(lic)
    end

    def ignored?(name)
      @ignored.include?(name)
    end

    def ignored_group?(name)
      @ignored_groups.include?(name)
    end

    #######
    # WRITE
    #######

    TXN = Struct.new(:who, :why, :safe_when) do
      def self.from_hash(txn)
        new(txn[:who], txn[:why], (txn[:when] && Time.parse(txn[:when]).getutc) || Time.now.getutc)
      end
    end

    def initialize
      @decisions = []
      @configuration = {}
      @packages = Set.new
      @licenses = Hash.new { |h, k| h[k] = Set.new }
      @approvals = {}
      @whitelisted = Set.new
      @ignored = Set.new
      @ignored_groups = Set.new
    end

    def add_package(name, version, txn = {})
      @decisions << [:add_package, name, version, txn]
      @packages << ManualPackage.new(name, version)
      self
    end

    def remove_package(name, txn = {})
      @decisions << [:remove_package, name, txn]
      @packages.delete(ManualPackage.new(name))
      self
    end

    def license(name, lic, txn = {})
      @decisions << [:license, name, lic, txn]
      @licenses[name] << License.find_by_name(lic)
      self
    end

    def unlicense(name, lic, txn= {})
      @decisions << [:unlicense, name, lic, txn]
      @licenses[name].delete(License.find_by_name(lic))
      self
    end

    def approve(name, txn = {})
      @decisions << [:approve, name, txn]
      @approvals[name] = TXN.from_hash(txn)
      self
    end

    def unapprove(name, txn = {})
      @decisions << [:unapprove, name, txn]
      @approvals.delete(name)
      self
    end

    def whitelist(lic, txn = {})
      @decisions << [:whitelist, lic, txn]
      @whitelisted << License.find_by_name(lic)
      self
    end

    def unwhitelist(lic, txn = {})
      @decisions << [:unwhitelist, lic, txn]
      @whitelisted.delete(License.find_by_name(lic))
      self
    end

    def ignore(name, txn = {})
      @decisions << [:ignore, name, txn]
      @ignored << name
      self
    end

    def heed(name, txn = {})
      @decisions << [:heed, name, txn]
      @ignored.delete(name)
      self
    end

    def ignore_group(name, txn = {})
      @decisions << [:ignore_group, name, txn]
      @ignored_groups << name
      self
    end

    def heed_group(name, txn = {})
      @decisions << [:heed_group, name, txn]
      @ignored_groups.delete(name)
      self
    end

    def name_project(name, txn = {})
      @decisions << [:name_project, name, txn]
      @project_name = name
      self
    end

    def unname_project(txn = {})
      @decisions << [:unname_project, txn]
      @project_name = nil
      self
    end

    def load_attributes(configuration = {})
      @configuration = configuration
      configuration = configuration.deep_symbolize_keys
      if configuration

        @whitelisted = Set.new(configuration[:whitelist].keys.map{|license| License.find_by_name(license.to_s)}) if configuration.key?(:whitelist)
        @ignored = Set.new(configuration[:ignore_dependencies].keys.map(&:to_s)) if configuration.key?(:ignore_dependencies)
        @ignored_groups = Set.new(configuration[:ignore_groups].keys.map(&:to_s)) if configuration.key?(:ignore_groups)
        @project_name = configuration[:project_name] if configuration.key?(:project_name)

        configuration[:whitelist].each do |license, value|
          next unless value.key? :include
          value[:include].each do |package, _txn|
            @licenses[package.to_s] << License.find_by_name(license.to_s)
          end
        end if configuration.key?(:whitelist)

        @approvals = configuration[:approvals].reduce({}) do |memo, (k, v)|
          memo.tap { |m| m[k.to_s] = TXN.from_hash(v) }
        end if configuration.key?(:approvals)

      end

      self
    end

    #########
    # PERSIST
    #########

    def self.saved!(file)
      restore(read!(file))
    end

    def save!(file)
      write!(persist, file)
    end

    def self.restore(persisted)
      result = new
      if persisted
        result.load_attributes(YAML.load(persisted))
      end
      result
    end

    def persist
      YAML.dump(@configuration)
    end

    def self.read!(file)
      file.read if file.exist?
    end

    def write!(value, file)
      file.dirname.mkpath
      file.open('w+') do |f|
        f.print value
      end
    end
  end
end

class Object
  def deep_symbolize_keys
    return self.reduce({}) do |memo, (k, v)|
      memo.tap { |m| m[k.to_sym] = v.deep_symbolize_keys }
    end if self.is_a? Hash

    return self.reduce([]) do |memo, v|
      memo << v.deep_symbolize_keys; memo
    end if self.is_a? Array

    self
  end
end
