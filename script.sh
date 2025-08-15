#!/bin/bash -e

if [ -n "${GITHUB_WORKSPACE}" ]
then
    git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
    cd "${GITHUB_WORKSPACE}" || exit 1
fi

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

TEMP_PATH="$(mktemp -d)"
PATH="${TEMP_PATH}:$PATH"

echo '::group::🐶 Installing reviewdog ... https://github.com/reviewdog/reviewdog'
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
echo '::endgroup::'

# Check if we should use bundler
if [ -f "Gemfile" ] && command -v bundle >/dev/null 2>&1; then
  echo "::notice::Using bundle exec standardrb (project's bundled version)"
  STANDARDRB_CMD="bundle exec standardrb"
else
  echo "::notice::Using gem install standardrb (version ${INPUT_STANDARD_VERSION:-latest})"
  if [ -n "${INPUT_STANDARD_VERSION}" ]; then
    gem install -N standard --version "${INPUT_STANDARD_VERSION}"
  else
    gem install -N standard
  fi
  STANDARDRB_CMD="standardrb"
fi

echo '::group:: Running standardrb with reviewdog 🐶 ...'

# shellcheck disable=SC2086
${STANDARDRB_CMD} ${INPUT_RUBOCOP_FLAGS} \
  | reviewdog \
    -f=rubocop \
    -name="${INPUT_TOOL_NAME}" \
    -reporter="${INPUT_REPORTER}" \
    -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
    -level="${INPUT_LEVEL}"

exit_code=$?
echo '::endgroup::'

exit $exit_code