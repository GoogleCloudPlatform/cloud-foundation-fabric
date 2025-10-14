import os
import subprocess
import json

def run_terraform(working_dir, variables):
    """
    Runs terraform init, plan, and apply.
    """
    # 1. Create .tfvars.json file
    tfvars_path = os.path.join(working_dir, "terraform.tfvars.json")
    with open(tfvars_path, "w") as f:
        json.dump(variables, f)

    # 2. Terraform Init
    init_process = subprocess.Popen(
        ["terraform", "init"],
        cwd=working_dir,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    stdout, stderr = init_process.communicate()
    if init_process.returncode != 0:
        raise Exception(f"Terraform init failed:\n{stderr}")
    print(stdout)

    # 3. Terraform Plan
    plan_process = subprocess.Popen(
        ["terraform", "plan", "-no-color"],
        cwd=working_dir,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    yield "\n--- Terraform Plan ---\n"
    for line in iter(plan_process.stdout.readline, ""):
        yield line
    for line in iter(plan_process.stderr.readline, ""):
        yield f"[STDERR] {line}"

    plan_process.stdout.close()
    plan_process.stderr.close()
    plan_return_code = plan_process.wait()

    if plan_return_code != 0:
        raise Exception(f"Terraform plan failed with return code {plan_return_code}")

    # 4. Terraform Apply
    apply_process = subprocess.Popen(
        ["terraform", "apply", "-auto-approve", "-no-color"],
        cwd=working_dir,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    yield "\n--- Terraform Apply ---\n"
    for line in iter(apply_process.stdout.readline, ""):
        yield line
    for line in iter(apply_process.stderr.readline, ""):
        yield f"[STDERR] {line}"

    apply_process.stdout.close()
    apply_process.stderr.close()
    return_code = apply_process.wait()

    if return_code != 0:
        raise Exception(f"Terraform apply failed with return code {return_code}")