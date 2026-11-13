class Paigy < Formula
  desc "Lets your AI agents reach you by call, push or card, and hear your answer"
  homepage "https://paigy.ai"
  url "https://registry.npmjs.org/@paigy/mcp/-/mcp-0.40.45.tgz"
  sha256 "37e63bbf0ca3051f3b90a526512cf2bb76ecd8f11a51736d932b92cd3e1e4fdd"
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
