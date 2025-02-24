class Phpstan < Formula
  desc "PHP Static Analysis Tool"
  homepage "https://github.com/phpstan/phpstan"
  url "https://github.com/phpstan/phpstan/releases/download/0.12.95/phpstan.phar"
  sha256 "2972b53d75d56fdb8bea4b97e700bff0914f10c1322ccc847815a27d2fa2449f"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "3d49981cedaca653968ff8310ce1476cef05a5897e50b248f9d2923c3f9c898d"
    sha256 cellar: :any_skip_relocation, big_sur:       "7cb836bf7bd11304d01626dd19dfcffb5bfa4d291ecf27dd0f4fd17a42867310"
    sha256 cellar: :any_skip_relocation, catalina:      "7cb836bf7bd11304d01626dd19dfcffb5bfa4d291ecf27dd0f4fd17a42867310"
    sha256 cellar: :any_skip_relocation, mojave:        "7cb836bf7bd11304d01626dd19dfcffb5bfa4d291ecf27dd0f4fd17a42867310"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "3d49981cedaca653968ff8310ce1476cef05a5897e50b248f9d2923c3f9c898d"
  end

  depends_on "php" => :test

  # Keg-relocation breaks the formula when it replaces `/usr/local` with a non-default prefix
  on_macos do
    pour_bottle? only_if: :default_prefix if Hardware::CPU.intel?
  end

  def install
    bin.install "phpstan.phar" => "phpstan"
  end

  test do
    (testpath/"src/autoload.php").write <<~EOS
      <?php
      spl_autoload_register(
          function($class) {
              static $classes = null;
              if ($classes === null) {
                  $classes = array(
                      'email' => '/Email.php'
                  );
              }
              $cn = strtolower($class);
              if (isset($classes[$cn])) {
                  require __DIR__ . $classes[$cn];
              }
          },
          true,
          false
      );
    EOS

    (testpath/"src/Email.php").write <<~EOS
      <?php
        declare(strict_types=1);

        final class Email
        {
            private string $email;

            private function __construct(string $email)
            {
                $this->ensureIsValidEmail($email);

                $this->email = $email;
            }

            public static function fromString(string $email): self
            {
                return new self($email);
            }

            public function __toString(): string
            {
                return $this->email;
            }

            private function ensureIsValidEmail(string $email): void
            {
                if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                    throw new InvalidArgumentException(
                        sprintf(
                            '"%s" is not a valid email address',
                            $email
                        )
                    );
                }
            }
        }
    EOS
    assert_match(/^\n \[OK\] No errors/,
      shell_output("#{bin}/phpstan analyse --level max --autoload-file src/autoload.php src/Email.php"))
  end
end
