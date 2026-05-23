---
name: kaggle-submit
description: Use when the user asks to render Kaggle notebook metadata from kaggle.yml, push a Kaggle notebook, or submit a competition file, with optional Python API fallback when the Kaggle CLI is unavailable.
---

# kaggle-submit

Use this skill when the user wants to work from `kaggle.yml` to push a Kaggle notebook, wait for it to finish, download output, or submit a competition file.

## Goals

- Read `kaggle.yml`.
- Select the active profile from top-level `profile:` unless the user overrides it.
- Build a clean Kaggle workdir.
- Render `kernel-metadata.json` dynamically.
- Push the notebook with `kaggle kernels push`.
- Optionally wait for completion and download output.
- Optionally submit the output file to the competition.

## Important distinction

There are two different operations:

1. Kernel push
   - Uploads or updates a Kaggle notebook version.
   - Uses the profile's `notebook`, `kernel`, and `sources` config.
   - This is not a competition submission.

2. Competition submit
   - Submits a local output file such as `submission.zip` or `submission.csv`.
   - Uses the profile's `submit.competition`, `submit.file`, and `submit.message`.

Do not say the competition submission is complete unless `kaggle competitions submit` or the Python API equivalent has actually succeeded.

## Expected config

The repository should contain `kaggle.yml` shaped like this:

```yaml
profile: rtx-pro-6000

profiles:
  rtx-pro-6000:
    notebook: nb/train_028-controlled_ablation_sweep.ipynb
    parent:
      url: https://www.kaggle.com/code/...
      kernel: someone/example-kernel
      title: Example kernel
    kernel:
      id: bloodymonday/train-028-controlled-ablation-sweep
      title: train_028_controlled_ablation_sweep
      code_file: train_028-controlled_ablation_sweep.ipynb
      language: python
      kernel_type: notebook
      is_private: true
      enable_gpu: true
      enable_internet: false
      accelerator: NvidiaRtxPro6000
      timeout: 43200
    sources:
      competition_sources:
        - nvidia-nemotron-model-reasoning-challenge
      dataset_sources: []
      kernel_sources: []
      model_sources: []
    submit:
      competition: nvidia-nemotron-model-reasoning-challenge
      file: submission.zip
      message: experiment message
```

`parent:` is optional. The helper script should ignore unknown keys and only rely on the fields above.

## Default workflow

1. Inspect `kaggle.yml`.
2. Confirm the selected profile and notebook.
3. Check that the notebook path exists.
4. Check Kaggle API availability.
   - Prefer the `kaggle` CLI if it is available.
   - If the CLI is missing but `kaggle.api.kaggle_api_extended.KaggleApi` imports, use the Python API fallback.
5. Render metadata with:

```bash
bash scripts/kaggle/kaggle_submit.sh --profile <profile> --push-only
```

6. If the user explicitly wants the final competition submission too, run:

```bash
bash scripts/kaggle/kaggle_submit.sh --profile <profile> --submit
```

## Safety checks

- Fail if `kaggle.yml` is missing.
- Fail if the selected profile is missing.
- Fail if the notebook path does not exist.
- Fail if `kernel.id`, `kernel.code_file`, or `submit.competition` is missing when needed.
- Remove stale files from `kaggle_workdir`.
- Print the selected profile, notebook path, kernel id, and submit target.

Before competition submit:

- Verify the output file exists locally.
- If the file is supposed to come from Kaggle output, download it first.
- Do not submit a stale local `submission.zip` without checking its origin.

## Output style

Report:

- selected profile
- notebook path
- kernel id
- Kaggle push result
- kernel version if available
- whether this was only a kernel push or also a competition submission
- final submission result if submitted
