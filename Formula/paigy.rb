class Paigy < Formula
  desc "Lets your AI agents reach you by call, push or card, and hear your answer"
  homepage "https://paigy.ai"
  url "https://registry.npmjs.org/@paigy/mcp/-/mcp-0.40.42.tgz"
  sha256 "75fcaf8661dc5596e7e97eb7cf967d470adb7e9813afe4329c0ce0b9cea26b96"
  license "MIT"

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    # Only Paigy's own commands: the package also names a bare `mcp`, which is too generic for a PATH.
    Dir["#{libexec}/bin/paigy-*"].each { |b| bin.install_symlink b }
  end

  test do
    assert_path_exists bin/"paigy-mcp"
    assert_path_exists bin/"paigy-listen"
  end
end
