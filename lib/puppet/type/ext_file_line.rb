require 'puppet/parameter/boolean'

Puppet::Type.newtype(:ext_file_line) do
  desc <<-EOT
    Ensures that a given line is contained within a file.
  EOT

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, :namevar => true) do
    desc 'An arbitrary name used as the identity of the resource.'
  end

  newparam(:match) do
    desc 'An optional regular expression to run against existing lines in the file;\n' +
        'if a match is found, we replace that line rather than adding a new line.'
  end

  newparam(:multiple) do
    desc 'An optional value to determine if match can change multiple lines.'
    newvalues(true, false)
  end

  newparam(:line) do
    desc 'The line to be appended to the file located by the path parameter.'
  end

  newparam(:path) do
    desc 'The file Puppet will ensure contains the line specified by the line parameter.'
    validate do |value|
      unless (Puppet.features.posix? and value =~ /^\//) or (Puppet.features.microsoft_windows? and (value =~ /^.:\// or value =~ /^\/\/[^\/]+\/[^\/]+/))
        raise(Puppet::Error, "File paths must be fully qualified, not '#{value}'")
      end
    end
  end

  newparam(:show_diff, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc "Whether to display differences when the file changes, defaulting to
        true.  This parameter is useful for files that may contain passwords or
        other secret data, which might otherwise be included in Puppet reports or
        other insecure outputs.  If the global `show_diff` setting
        is false, then no diffs will be shown even if this parameter is true."

    defaultto :true
  end

  newparam(:match_only_one_run, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc "Causes the resource to be considered up-to-date as soon as `match` stops matching,
        typically because a replacement already happened on the previous Puppet run"

    defaultto :false
  end

  # Autorequire the file resource if it's being managed
  autorequire(:file) do
    self[:path]
  end

  validate do
    unless self[:path]
      raise(Puppet::Error, "Must specify the 'path' parameter")
    end

    if self[:ensure] == :present
      unless self[:line]
        raise(Puppet::Error, "Must specify the 'line' parameter when ensure is present")
      end
    end

    if self[:match_only_one_run] and not self[:match]
      raise(Puppet::Error, "Must specify the 'match' parameter when 'match_only_one_run' is true")
    end
  end
end
