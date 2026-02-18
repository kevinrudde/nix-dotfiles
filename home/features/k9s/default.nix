{ pkgs, config, ... }: {

  catppuccin.k9s = {
    enable = true;
    flavor = "mocha";
  };

  programs.k9s = {
    enable = true;
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
