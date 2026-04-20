{ pkgs, config, ... }: {

  catppuccin.k9s = {
    enable = true;
    flavor = "mocha";
  };

  programs.k9s = {
    enable = true;
    hotKeys = {
      ctrl-o = {
        shortCut = "Ctrl-O";
        description = "Switch to node";
        command = "node /$COL-NODE";
        keepHistory = true;
      };
    };
    plugins = {
      eks-node-viewer = {
        shortCut = "Shift-X";
        description = "eks-node-viewer";
        scopes = [ "node" ];
        background = false;
        command = "bash";
        args = [
          "-c"
          ''
            env $(kubectl config view --context $CONTEXT --minify -o json | jq -r ".users[0].user.exec.env[] | select(.name == \"AWS_PROFILE\") | \"AWS_PROFILE=\" + .value" && kubectl config view --context $CONTEXT --minify -o json | jq -r ".users[0].user.exec.args | \"AWS_REGION=\" + .[1]") eks-node-viewer --context $CONTEXT --resources cpu,memory --extra-labels karpenter.sh/nodepool,eks-node-viewer/node-age --node-sort=creation=dsc
          ''
        ];
      };
      ssm-node = {
        shortCut = "s";
        confirm = false;
        description = "Start an AWS SSM session to the node";
        scopes = [ "node" ];
        background = false;
        command = "bash";
        args = [
          "-c"
          ''
            set -euo pipefail

            AWS_PROFILE_VALUE="$(kubectl config view --context "$CONTEXT" --minify -o json | jq -r '.users[0].user.exec.env[]? | select(.name == "AWS_PROFILE") | .value')"
            AWS_REGION_VALUE="$(kubectl config view --context "$CONTEXT" --minify -o json | jq -r '(.users[0].user.exec.args // []) as $args | [range(0; $args | length) | select($args[.] == "--region") | $args[. + 1]][0] // empty')"
            PROVIDER_ID="$(kubectl get node "$NAME" --context "$CONTEXT" -o jsonpath='{.spec.providerID}')"
            INSTANCE_ID="''${PROVIDER_ID##*/}"

            if [ -n "$AWS_PROFILE_VALUE" ]; then
              export AWS_PROFILE="$AWS_PROFILE_VALUE"
            fi

            if [ -n "$AWS_REGION_VALUE" ]; then
              export AWS_REGION="$AWS_REGION_VALUE"
            fi

            aws ssm start-session --target "$INSTANCE_ID"
          ''
        ];
      };
      refresh-external-secrets = {
        shortCut = "Shift-R";
        confirm = false;
        scopes = [ "externalsecrets" ];
        description = "Refresh the externalsecret";
        command = "bash";
        background = true;
        args = [
          "-c"
          "kubectl annotate externalsecrets.external-secrets.io --context $CONTEXT -n $NAMESPACE $NAME force-sync=$(date +%s) --overwrite"
        ];
      };
      refresh-push-secrets = {
        shortCut = "Shift-R";
        confirm = false;
        scopes = [ "pushsecrets" ];
        description = "Refresh the pushsecret";
        command = "bash";
        background = true;
        args = [
          "-c"
          "kubectl annotate pushsecrets.external-secrets.io --context $CONTEXT -n $NAMESPACE $NAME force-sync=$(date +%s) --overwrite"
        ];
      };
      stern = {
        shortCut = "Ctrl-Y";
        confirm = false;
        description = "Logs <Stern>";
        scopes = [ "pods" ];
        command = "stern";
        background = false;
        args = [
          "--tail"
          "50"
          "$FILTER"
          "-n"
          "$NAMESPACE"
          "--context"
          "$CONTEXT"
        ];
      };
    };
  };
}
