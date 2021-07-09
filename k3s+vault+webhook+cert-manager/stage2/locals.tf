locals {
  stage0 = data.terraform_remote_state.stage0.outputs
  stage1 = data.terraform_remote_state.stage1.outputs
}
