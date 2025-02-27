require "language/node"

class GatsbyCli < Formula
  desc "Gatsby command-line interface"
  homepage "https://www.gatsbyjs.org/docs/gatsby-cli/"
  # gatsby-cli should only be updated every 10 releases on multiples of 10
  url "https://registry.npmjs.org/gatsby-cli/-/gatsby-cli-4.10.0.tgz"
  sha256 "2635d4a9e30d9db38419ff6246e961d21d035efa8124d3bf1e717fb586950f9f"
  license "MIT"

  bottle do
    sha256                               arm64_monterey: "fb0836bf0f2de8e14b57e0df6eaaae89e025c80888128485a39de0d1a6797e11"
    sha256                               arm64_big_sur:  "2f7820febdbd583760a5202d7585fbb15565ca036c767978b4c563306c72afa8"
    sha256                               monterey:       "927f52b7d2dbc20d6541cbc21f01e44cf11b6ac242dc52d3e50f830f7bd0f055"
    sha256                               big_sur:        "4a99de7ca8bcb35901f925cb381d5a3008b49a3712c2a3d8b514426c11a30732"
    sha256                               catalina:       "2519e98356537685e1b36628210ec640329592a8704ed5d9dfb9c6cf330dce57"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "3aae632db5d18c0cb0b7d37081bad0b3903b78b88b1c1378000318e96354bbd1"
  end

  depends_on "node"

  on_macos do
    depends_on "macos-term-size"
  end

  on_linux do
    depends_on "xsel"
  end

  def install
    system "npm", "install", *Language::Node.std_npm_install_args(libexec)
    bin.install_symlink Dir[libexec/"bin/*"]

    # Avoid references to Homebrew shims
    node_modules = libexec/"lib/node_modules/#{name}/node_modules"
    rm_f node_modules/"websocket/builderror.log"

    # Remove incompatible pre-built binaries
    os = OS.kernel_name.downcase
    arch = Hardware::CPU.intel? ? "x64" : Hardware::CPU.arch.to_s
    node_modules.glob("{lmdb,msgpackr-extract}/prebuilds/*").each do |dir|
      if dir.basename.to_s != "#{os}-#{arch}"
        dir.rmtree
      elsif OS.linux?
        dir.glob("*.musl.node").map(&:unlink)
      end
    end

    term_size_vendor_dir = node_modules/"term-size/vendor"
    term_size_vendor_dir.rmtree # remove pre-built binaries
    if OS.mac?
      macos_dir = term_size_vendor_dir/"macos"
      macos_dir.mkpath
      # Replace the vendored pre-built term-size with one we build ourselves
      ln_sf (Formula["macos-term-size"].opt_bin/"term-size").relative_path_from(macos_dir), macos_dir
    end

    clipboardy_fallbacks_dir = node_modules/"clipboardy/fallbacks"
    clipboardy_fallbacks_dir.rmtree # remove pre-built binaries
    if OS.linux?
      linux_dir = clipboardy_fallbacks_dir/"linux"
      linux_dir.mkpath
      # Replace the vendored pre-built xsel with one we build ourselves
      ln_sf (Formula["xsel"].opt_bin/"xsel").relative_path_from(linux_dir), linux_dir
    end
  end

  test do
    system bin/"gatsby", "new", "hello-world", "https://github.com/gatsbyjs/gatsby-starter-hello-world"
    assert_predicate testpath/"hello-world/package.json", :exist?, "package.json was not cloned"
  end
end
