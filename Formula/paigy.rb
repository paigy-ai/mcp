class Paigy < Formula
  desc "Lets your AI agents reach you by call, push or card, and hear your answer"
  homepage "https://paigy.ai"
  url "https://registry.npmjs.org/@paigy/mcp/-/mcp-0.40.43.tgz"
  sha256 "88fde34f2fb7b2da775512e480c21aa71a6ecac2dfa2f214af8cd097661bdd4f"
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
