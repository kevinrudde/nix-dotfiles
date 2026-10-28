# Exec credential plugin wrapper for kubeconfig: awsx-guard <aws-profile> <aws args...>
# With AWSX_GUARD=1 the caller's AWS_PROFILE must equal <aws-profile>.
profile=$1
shift

if [ "${AWSX_GUARD:-}" = 1 ] && [ "${AWS_PROFILE:-}" != "$profile" ]; then
  echo "awsx-guard: AWS_PROFILE=${AWS_PROFILE:-<unset>} does not match cluster profile $profile" >&2
  exit 1
fi

exec env AWS_PROFILE="$profile" aws "$@"
