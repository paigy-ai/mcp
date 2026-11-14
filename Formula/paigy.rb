class Paigy < Formula
  desc "Lets your AI agents reach you by call, push or card, and hear your answer"
  homepage "https://paigy.ai"
  url "https://registry.npmjs.org/@paigy/mcp/-/mcp-0.40.47.tgz"
  sha256 "1bfbd35e21db9b214f56230d6fd6abf82abb6c5dcc0ef64a7c31c69ee3bf23ac"
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
