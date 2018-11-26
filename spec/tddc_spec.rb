describe 'tddc' do
  it 'can pass arguments to a command, and return result (example 1)' do
    output = `#{__dir__ + '/../bin/tddc echo "0 failures, 1 passed"'}`
    expect(output).to eq("0 failures, 1 passed\n")
  end

  it 'can pass arguments to a command, and return result (example 2)' do
    output = `#{__dir__ + '/../bin/tddc echo "1 failures, 0 passed"'}`
    expect(output).to eq("1 failures, 0 passed\n")
  end

  it 'can call a command' do
    Dir.mkdir(__dir__ + '/../tmp/') unless Dir.exist?(__dir__ + '/../tmp/')
    File.unlink(__dir__ + '/../tmp/yes') if File.exist?(__dir__ + '/../tmp/yes')

    `#{__dir__ + '/../bin/tddc ./spec/bin/command_spy'}`

    expect(File.exist?(__dir__ + '/../tmp/yes')).to be true
  end

  it 'can stream output from a command' do
    Dir.mkdir(__dir__ + '/../tmp/') unless Dir.exist?(__dir__ + '/../tmp/')
    File.unlink(__dir__ + '/../tmp/streaming_file') if File.exist?(__dir__ + '/../tmp/streaming_file')
    File.open(__dir__ + '/../tmp/streaming_file', 'w') {}

    require 'socket'

    stdout_pipe, stdout_writing_pipe = IO.pipe
    stderr_pipe, stderr_writing_pipe = IO.pipe
    cmd_pid = Process.spawn(__dir__ + '/../bin/tddc tail "-f tmp/streaming_file"',
                            out: stdout_writing_pipe.fileno,
                            err: stderr_writing_pipe.fileno)
    stdout_writing_pipe.close
    stderr_writing_pipe.close

    File.open(__dir__ + '/../tmp/streaming_file', 'a') do |file|
      file.write("Hello world\n")
    end

    expect(stdout_pipe.gets).to eq("Hello world\n")
    Process.kill('INT', cmd_pid)
    Process.detach(cmd_pid)
    expect(stderr_pipe.gets).to be_nil

    output = `ps aux | grep "tail -f streaming_file" | grep -v grep`
    expect(output).not_to include('tail -f streaming_file')
  end
end
