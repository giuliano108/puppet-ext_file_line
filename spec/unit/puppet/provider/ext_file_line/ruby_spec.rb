require 'spec_helper'
require 'puppet/type/ext_file_line'

describe Puppet::Type.type(:ext_file_line).provider(:ruby) do
  let(:tmpfile) { File.join(tmpdir, 'test_file') }

  let(:resource) do
    Puppet::Type.type(:ext_file_line).new(
      name: 'test',
      path: tmpfile,
      line: 'test line',
      provider: described_class.name
    )
  end

  let(:provider) { resource.provider }

  before(:each) do
    File.open(tmpfile, 'w') { |f| f.write("# Header\nexisting line\n") }
  end

  after(:each) do
    File.delete(tmpfile) if File.exist?(tmpfile)
  end

  describe '#exists?' do
    context 'when the line does not exist and (implied) "ensure: present"' do
      it 'returns false' do
        expect(provider.exists?).to eq(false)
      end
    end

    context 'when the line does not exist and "ensure: absent"' do
      it 'returns false, to say that there is nothing to change' do
        resource[:ensure] = 'absent'
        expect(provider.exists?).to eq(false)
      end
    end

    context 'when the line exists' do
      before do
        File.open(tmpfile, 'a') { |f| f.puts("test line") }
      end

      it 'returns true' do
        expect(provider.exists?).to eq(true)
      end
    end

    context 'when the line does not exist and "ensure: absent"' do
      it 'returns false' do
        resource[:ensure] = 'absent'
        expect(provider.exists?).to eq(false)
      end
    end

    context 'with a matching pattern and "ensure: absent"' do
      it 'returns true, to say that the line should be deleted' do
        resource[:ensure] = 'absent'
        resource[:match] = '^existing'
        expect(provider.exists?).to eq(true)
      end
    end

    context 'with a match pattern and (implied) "ensure: present"' do
      it 'returns true when pattern matches and the line would not be changed' do
        resource[:line] = 'existing line'
        resource[:match] = '^existing.*$'
        expect(provider.exists?).to eq(true)
      end
    end

    context 'with a _partial_ match pattern and (implied) "ensure: present"' do
      it 'returns false when the replacing the partial pattern would result in a changed line' do
        resource[:match] = '^existing'
        expect(provider.exists?).to eq(false)
      end

      it 'returns true when the replacing the partial pattern would result in an unchanged line' do
        resource[:match] = '^existing'
        resource[:line] = 'existing'
        expect(provider.exists?).to eq(true)
      end
    end

    context 'with `match_only_one_run`' do
      it 'Puppet converges on the second run, after replacing a line in the first' do
        resource[:match] = '^existing line$'
        resource[:line] = 'new line'
        resource[:match_only_one_run] = true
        expect(provider.exists?).to eq(false)
        provider.create
        provider.instance_variable_set(:@lines, nil)  # causes the file to be re-read
        expect(provider.exists?).to eq(true)
      end
    end
  end

  describe '#create' do
    it 'adds the line to the file' do
      provider.create
      expect(File.read(tmpfile)).to include('test line')
    end

    context 'with regex backreferences' do
      before do
        File.open(tmpfile, 'w') do |f|
          f.write("enable-cache passwd no\n")
        end
      end

      let(:resource) do
        Puppet::Type.type(:ext_file_line).new(
          name: 'test',
          path: tmpfile,
          line: '\1yes',
          match: '^(.*enable-cache.*passwd.*)(yes|no)$',
          provider: described_class.name
        )
      end

      it 'replaces with backreference substitution' do
        provider.create
        expect(File.read(tmpfile)).to match(/enable-cache passwd yes/)
      end
    end
  end

  describe '#destroy' do
    before do
      File.open(tmpfile, 'w') { |f| f.write("test line\n") }
    end

    context 'with a line' do
      let(:resource) do
        Puppet::Type.type(:ext_file_line).new(
          name: 'test',
          ensure: 'absent',
          path: tmpfile,
          line: 'test line',
          provider: described_class.name
        )
      end

      it 'removes the line from the file' do
        provider.destroy
        expect(File.read(tmpfile)).not_to include('test line')
      end
    end

    context 'with a match' do
      let(:resource) do
        Puppet::Type.type(:ext_file_line).new(
          name: 'test',
          ensure: 'absent',
          path: tmpfile,
          match: '^test',
          provider: described_class.name
        )
      end

      it 'removes the line from the file' do
        provider.destroy
        expect(File.read(tmpfile)).not_to include('test line')
      end
    end

    context 'when multiple lines match and "multiple: false" (default)' do
      before do
        File.open(tmpfile, 'w') { |f| f.write("test line\ntest line\n") }
      end

      let(:resource) do
        Puppet::Type.type(:ext_file_line).new(
          name: 'test',
          ensure: 'absent',
          path: tmpfile,
          line: 'test line',
          provider: described_class.name
        )
      end

      it 'raises an error' do
        expect { provider.destroy }.to raise_error(Puppet::Error)
      end
    end

    context 'when multiple lines match and "multiple: true"' do
      before do
        File.open(tmpfile, 'w') { |f| f.write("test line\ntest line\n") }
      end

      let(:resource) do
        Puppet::Type.type(:ext_file_line).new(
          name: 'test',
          ensure: 'absent',
          path: tmpfile,
          line: 'test line',
          multiple: 'true',
          provider: described_class.name
        )
      end

      it 'removes all the lines' do
        provider.destroy
        expect(File.read(tmpfile)).to eq('')
      end
    end
  end

  describe 'diff output' do
    it 'shows changes with --show-diff' do
      sd = Puppet[:show_diff]
      Puppet[:show_diff] = true
      resource[:show_diff] = true
      expect(provider).to receive(:notice).with(/^---/)
      provider.create
      Puppet[:show_diff] = sd
    end
  end
end
