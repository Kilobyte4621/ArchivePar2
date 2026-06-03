# ArchivePar2 Shell Automation Utility (v0.12)

This utility suite provides a robust framework for **data backups focusing on long-term integrity**. By combining **Zstandard (zstd)** for high-speed compression, **PAR2** for error correction, and **BLAKE3** for cryptographic hashing, it ensures that your archived data is not only compressed but also recoverable and verifiable.

---

## Quick Start & Dependencies

### Technical Dependencies

To function correctly, the suite requires the following tools to be installed on your system:

* **`zstd`**: High-performance compression.
* **`par2`**: Reed-Solomon error correction.
* **`pv` (Pipe Viewer)**: For real-time progress bars.
* **`b3sum`**: For ultra-fast BLAKE3 hashing.

### Getting Started

1. Clone or download the scripts into a directory.
2. Source the utilities into your environment using the provided helper:
```bash
./add2bash.sh
```

3. If you're not opening a new terminal, re-source your `.bashrc` file:
```bash
source ~/.bashrc
```

4. Run a complete, auto-verified backup of any directory:
```bash
backup /path/to/your/folder
```

---

## 1. Core Component: `archivepar2` (v0.12)

The `archivepar2` function is the primary creation engine. It transforms a target directory into a protected, compressed archive while providing real-time performance metrics.

### Key Functionalities

* **Intelligent Path Sanitization:** It automatically cleans folder names to be shell-safe (lowercase, replacing spaces with underscores, and removing special characters) before creating a dedicated `{folder}-bak` directory.
* **Flexible Archiving Modes:** * **Split Mode (Default):** Breaks the archive into parts (defaulting to **2GB** chunks) to facilitate easier transport across different filesystems or cloud storage.
* **Single Mode (`--SINGLE`):** Forces the creation of one single large archive file.


* **Content Integrity Verification:** Unless the **`--FAST`** flag is used, the script performs a `tar --diff` immediately after compression to ensure the archive matches the source 1:1.
* **Cryptographic Manifests:** It generates a **BLAKE3 manifest** (`.blake3`) to record the exact cryptographic signature of the backup parts.

### Arguments & Flags

* `--SINGLE`: Creates a single archive instead of split parts.
* `--FAST`: Skips the post-compression `tar --diff` check to speed up the process.
* `Size (e.g., 500M, 4G)`: Customizes the maximum size of each archive part in split mode.

### Detailed Workflow of `archivepar2`

The `archivepar2` function is designed to be a "set-and-forget" creation engine that ensures the backup is valid before it even finishes the process.

1. **Environment and Argument Handling**:
* The script uses `set -o pipefail` to ensure that if any command in a pipeline (like `tar` or `zstd`) fails, the entire script returns an error.
* It implements a dynamic argument loop that supports **`--SINGLE`** (for one large file), **`--FAST`** (to skip post-compression verification), and custom **split sizes** (e.g., `500M`, `4G`).


2. **Sanitization and Logging**:
* The source folder name is sanitized: it is converted to **lowercase**, spaces become **underscores**, and special characters are removed.
* A dedicated **Session Log (`.log`)** is initialized, recording the start timestamp, source path, arguments used, and hardware performance metrics.


3. **Compression Strategy**:
* **Split Mode (Default)**: The script breaks the archive into parts defined by the `maxsize`. It now uses `pv` (Pipe Viewer) during part collection to provide a real-time progress bar for the user.
* **Single Mode**: Bypasses the splitting logic to create one `.tar.zst` file.


4. **The "Integrity First" Check**:
* Unless `--FAST` is specified, the script runs `check_content_integrity`. This function performs a `tar --diff` between the archive and the source directory to ensure the compression was 100% accurate before moving to the next step.


5. **PAR2 and Manifest Generation**:
* It generates **PAR2 recovery blocks**, which allow for future repair of the archive if the storage media fails or bits rot.
* It creates a **BLAKE3 manifest** (`.blake3`), providing an ultra-fast cryptographic hash of the archive for future verification.



---

## 2. Restoration & Recovery: `restorepar2` (v0.4)

This script acts as the guardian of your data, used to verify the health of archives and restore them.

### Key Functionalities

* **Automatic Detection:** The script automatically fingerprints the backup directory to determine if it is dealing with a single-file or split-file archive.
* **PAR2 Self-Healing:** It runs a block integrity check. If the archive is found to be corrupted, it automatically attempts a **`par2 repair`** to recover missing or damaged data using redundancy blocks.
* **Verified Extraction:** When run in `extract` mode, it unpacks the archive into a new directory suffixed with `-restored` and performs real-time BLAKE3 hashing to verify data integrity during extraction.
* **Full Structural Check (`--FULL`):** Allows for deeper levels of structural verification of the archive files.

### Arguments & Flags

* **`EXTRACT`**: Switches the mode from verification to **full restoration**. The script will unpack the archive into a new directory suffixed with `-restored`.
* **`--FULL`, `--FULL=1`, or `--FULL=2**`: Enables **Deep Structural Checks**. These options trigger different levels of structural integrity verification beyond the standard PAR2 and BLAKE3 checks.
* **Input Folder**: The first non-flag argument is treated as the path to the backup directory.

### Detailed Workflow of `restorepar2`

The `restorepar2` utility is the "guardian" of the archive, focusing on resilience and verified extraction.

1. **Archive Fingerprinting**:
* The script automatically detects whether it is working with a **single-file** or **split-file** archive by scanning for `.tar.zst` or `.tar.zst.part-*` patterns.
* It identifies the required `.par2` index file to begin the recovery process.


2. **Phase 1: Proactive Resilience (Verify & Repair)**:
* The script first runs `par2 verify`.
* **Auto-Repair**: A critical feature of v0.4 is that if verification fails, it does not simply quit; it immediately attempts a **`par2 repair`** to fix corrupted blocks using the redundancy data.


3. **Phase 2: Cryptographic Validation**:
* It utilizes the **BLAKE3 manifest** to verify the archive’s integrity. The `verify_blake3_match` helper is designed to isolate the hash of the archive files from the multi-line manifest format.


4. **Phase 3: Verified Extraction**:
* If the `EXTRACT` mode is used, the script creates a new directory suffixed with **`-restored`** to prevent overwriting existing data.
* Extraction is performed with **real-time BLAKE3 hashing**, ensuring the data being written to disk matches the cryptographic signature of the original archive.


5. **Performance Auditing**:
* Upon completion, the script generates a **Performance Summary**, detailing the time spent on PAR2 checks, BLAKE3 verification, structural checks, and extraction.



---

## 3. Automation Wrappers

### `backup` (v0.1)

A high-level orchestrator that executes the full pipeline: it calls `archivepar2` to create the backup and then immediately triggers `restorepar2` in verification mode. This ensures a backup is only considered "successful" if its integrity is confirmed right after creation.

* **Dynamic Flag Passing**: It is designed to interpret flags and automatically pass them to the underlying engines. For example, flags related to creation (like `--SINGLE`) are passed to `archivepar2`, while restore-level settings are passed to `restorepar2`.

### `folderbkp` (v0.1)

A batch processor that iterates through an entire parent directory, applying the `backup` function to every sub-folder and file.

* **Hidden File Support:** It utilizes `dotglob` to ensure hidden configuration files (like `.git`) are included in the backup.
* **Robustness:** It captures all extra arguments (like custom sizes or speed flags) and passes them safely to each individual backup task.

#### Arguments and flags

* **`[extra_args]`**: Any arguments provided after the parent directory (such as `--FAST`, `--SINGLE`, or a custom part size) are captured and **repassed** to each individual `backup` call.
* **Environment Handling**: It automatically enables `nullglob` and `dotglob` during execution to ensure that empty directories and hidden files (starting with `.`) are included in the process.

---

## 4. Performance Monitoring & Logging

The utility provides extensive feedback for every session, which is both displayed in the terminal (via `pv` progress bars) and saved to a **Session Log** (`.log`).

**The Performance Summary includes:**

* **Compression Metrics:** Duration and status of the zstd compression.
* **Tar Check:** Time taken for the 1:1 bit-comparison against the source.
* **PAR2 Create/Check:** Time spent generating or verifying recovery blocks.
* **BLAKE3/Structure Checks:** Verification status of cryptographic hashes.
* **Total Elapsed Time:** A final timer (MM:SS) for the entire operation.

---

## 5. Environment & Utilities

* **`add2bash` (v0.0):** Simplifies the installation of these scripts by appending a sourcing loop to your `~/.bashrc`, making all tools available globally in your shell.
	#### Arguments and flags
	* **`[text]`**: An optional specific string (like an alias or environment variable) to append to your `~/.bashrc`.
	* **No Argument (Default)**: If no text is provided, it generates a shell loop that automatically **sources all `.sh` files** found in your current working directory.
* **`sh2txt` (v0.1):** A utility to convert `.sh` scripts into `.txt` files for documentation or sharing purposes, including a recursive option for large directories.
	#### Arguments and flags
	* **`[directory]`**: Specifies the target directory to scan for `.sh` files. If omitted, it defaults to the **current directory (`.`)**.
	* **Recursive Option**: Although commented out in the provided source, the script includes logic for a **recursive search** using `find` to process nested subdirectories.



---
