# 04 - Storage Layout

Do this chapter **before** Docker and before any app (Immich, Home Assistant, Jellyfin). Steps match **Unraid 7.3.2** WebGUI labels.

Goal: assign disks, create empty shares, start the array. Do **not** install apps here.

This build uses the SSD pool named **`cache`** (Unraid default). Primary storage for appdata/system shares is **`cache`**, not Array.

## Devices

| Device | Role | Availability |
|---|---|---|
| Acer Predator GM7000 1 TB | SSD pool (`cache`) for appdata and databases | 24/7 |
| Seagate IronWolf 6 TB | Array disk 1 (no parity) for photos, documents, media | 24/7 |
| Seagate Exos 6 TB | Unassigned Devices backup disk (add when ready) | Weekly only |

No parity disk. You accept about one week of risk on new data in exchange for a separate backup copy.

### Expected Unraid warnings (do not panic)

With parity left empty, Unraid will show banners like:

| Message | Meaning |
|---|---|
| **STARTED, ARRAY UNPROTECTED** | Array is running, but there is no parity disk to rebuild from if Disk 1 fails |
| **SOME OR ALL FILES UNPROTECTED** (on shares) | Those share files live on the array (and/or a single-device pool) without parity protection |

That is intentional for this design. Protection comes from the **weekly Exos backup** (chapter `10`), not from parity.

**What you should do:**

1. Keep using the server — you do not need to “fix” these warnings by adding parity unless you change the design.
2. Do **not** assign the Exos as parity (it is the backup disk).
3. Finish apps, then set up weekly backups (`15` → `10`).
4. Optionally keep a second copy of irreplaceable photos off-site (chapter `09` / `10`).

**If you later want the warnings gone:** add a second large HDD as **Parity**, leave the Exos as Unassigned Devices backup. That is optional and not required for Phase 1.

## Step 1 — Create the SSD pool

1. Open the **Main** tab.
2. Under **Pool Devices**, click **Add Pool** (or fill the empty pool slot).
3. Fill:

| Field | Value |
|---|---|
| Pool name | `cache` |
| Slots / device | Acer Predator GM7000 (match by serial) |
| File system | **xfs** (simple single-drive pool) |
| Partition format | GPT / Unraid default |

4. Do not start the array yet if the IronWolf is not assigned — finish Step 2 first.

## Step 2 — Assign the IronWolf

1. Still on **Main → Array Devices**.
2. Fill:

| Slot | Value |
|---|---|
| Parity | **Unassigned** (leave empty) |
| Disk 1 | Seagate IronWolf 6 TB (match by serial) |
| Disk 1 file system (after format) | **xfs** |

3. Confirm serial numbers match the physical drives.
4. Click **Start** at the bottom of **Main**.
5. If Unraid prompts to format new devices, review the checked disks carefully, then format.

## Step 3 — Global Share Settings

1. Open **Settings → Global Share Settings**.
2. Fill:

| Field | Value |
|---|---|
| Enable user shares | **Yes** |
| Permit exclusive shares | **Yes** |
| Included disk(s) (global) | leave default / all (unless you have a reason to restrict) |
| Excluded disk(s) (global) | blank |

3. Click **Apply**.

Exclusive access keeps `appdata` / `system` on the SSD pool without FUSE overhead when Primary is the pool and Secondary is None.

## Step 4 — Create shares (folders only)

1. Open **Shares**.
2. Click **Add Share**.
3. Fill the fields for each share using the templates below.
4. Click **Add Share**.
5. Repeat until every share in the lists exists.
6. Leave shares empty. Apps fill them later.

### How to read the share forms

After **Add Share** (or when editing an existing share on **Shares → [name]**), fill both **Share Settings** and **SMB Security Settings**.

#### Share Settings

| Field | What to do |
|---|---|
| Share name | Exact name below (lowercase, no spaces) |
| Comments | Short description (optional but recommended) |
| Minimum free space | Floor so a nearly full disk is not chosen for a huge write. Examples: `20G` for appdata, `50G`–`100G` for large media/photo shares. Leave blank only if you accept Unraid’s default. |
| Primary storage | Where new files are written first (`cache` or **Array**) |
| Secondary storage | Overflow / mover target. Use **None** for this build |
| Enable Copy-on-write | **Auto** (Unraid default; do not force Yes/No unless you have a specific Btrfs reason) |
| Allocation method | Only appears when Primary or Secondary is **Array**. Use **High-water** |
| Split level | Only for Array shares. Use **Automatically split any directory as required** (or blank / Automatic) on a single-disk array |
| Included disk(s) | For Array shares: **disk1** (or All — only disk1 exists) |
| Excluded disk(s) | blank |
| Mover action | Hidden / irrelevant when Secondary = **None** |

#### SMB Security Settings

| Field | What to do |
|---|---|
| Export | **No** = hidden from network. **Yes** = normal SMB share. **Yes (Time Machine)** = only for a dedicated Time Machine share (not used for Phase 1 data shares below) |
| Time Machine volume size limit | Leave **blank** unless Export is **Yes (Time Machine)**. If you add TM later, set a max size in MB (example `1048576` = 1 TB reported cap) |
| Case-sensitive names | **Auto** (recommended for mixed Mac/Windows clients) |
| Security | **Private** = only listed users (best for personal data). **Secure** = guests read-only; users can have write. **Public** = no password (avoid; modern Windows often blocks it) |

With only Disk 1 in the array, allocation method and split level barely matter, but set them so the form is complete.

### Pool shares (Primary = `cache`, Secondary = None)

Create each of these. After creation, open the share and confirm **Exclusive access** shows **Yes** (needs Step 3).

#### `appdata`

| Section | Field | Value |
|---|---|---|
| Share Settings | Share name | `appdata` |
| Share Settings | Comments | Docker configs and databases |
| Share Settings | Minimum free space | `20G` |
| Share Settings | Primary storage | `cache` |
| Share Settings | Secondary storage | **None** |
| Share Settings | Enable Copy-on-write | **Auto** |
| Share Settings | Allocation / Split / Include | not used (pool-only) |
| SMB Security Settings | Export | **No** |
| SMB Security Settings | Time Machine volume size limit | blank |
| SMB Security Settings | Case-sensitive names | **Auto** |
| SMB Security Settings | Security | leave default (not exported) |

#### `system`

| Section | Field | Value |
|---|---|---|
| Share Settings | Share name | `system` |
| Share Settings | Comments | Docker system data |
| Share Settings | Minimum free space | `10G` |
| Share Settings | Primary storage | `cache` |
| Share Settings | Secondary storage | **None** |
| Share Settings | Enable Copy-on-write | **Auto** |
| SMB Security Settings | Export | **No** |
| SMB Security Settings | Time Machine volume size limit | blank |
| SMB Security Settings | Case-sensitive names | **Auto** |
| SMB Security Settings | Security | leave default (not exported) |

#### `domains` (optional)

| Section | Field | Value |
|---|---|---|
| Share Settings | Share name | `domains` |
| Share Settings | Comments | Future VMs |
| Share Settings | Minimum free space | `50G` |
| Share Settings | Primary storage | `cache` |
| Share Settings | Secondary storage | **None** |
| Share Settings | Enable Copy-on-write | **Auto** |
| SMB Security Settings | Export | **No** |
| SMB Security Settings | Time Machine volume size limit | blank |
| SMB Security Settings | Case-sensitive names | **Auto** |
| SMB Security Settings | Security | leave default (not exported) |

#### `database-backups-staging`

| Section | Field | Value |
|---|---|---|
| Share Settings | Share name | `database-backups-staging` |
| Share Settings | Comments | Temporary DB dumps before weekly backup |
| Share Settings | Minimum free space | `10G` |
| Share Settings | Primary storage | `cache` |
| Share Settings | Secondary storage | **None** |
| Share Settings | Enable Copy-on-write | **Auto** |
| SMB Security Settings | Export | **No** |
| SMB Security Settings | Time Machine volume size limit | blank |
| SMB Security Settings | Case-sensitive names | **Auto** |
| SMB Security Settings | Security | leave default (not exported) |

### Array shares (Primary = Array, Secondary = None)

Do **not** set Primary to `cache` for these. Large libraries stay on the IronWolf.

#### `photos`

| Section | Field | Value |
|---|---|---|
| Share Settings | Share name | `photos` |
| Share Settings | Comments | Immich photo library |
| Share Settings | Minimum free space | `50G` |
| Share Settings | Primary storage | **Array** |
| Share Settings | Secondary storage | **None** |
| Share Settings | Enable Copy-on-write | **Auto** |
| Share Settings | Allocation method | **High-water** |
| Share Settings | Split level | Automatically split any directory as required |
| Share Settings | Included disk(s) | **disk1** |
| Share Settings | Excluded disk(s) | blank |
| SMB Security Settings | Export | **Yes** (or **No** until chapter `15`) |
| SMB Security Settings | Time Machine volume size limit | blank |
| SMB Security Settings | Case-sensitive names | **Auto** |
| SMB Security Settings | Security | **Private** |

#### `documents`

| Section | Field | Value |
|---|---|---|
| Share Settings | Share name | `documents` |
| Share Settings | Comments | Personal documents |
| Share Settings | Minimum free space | `20G` |
| Share Settings | Primary storage | **Array** |
| Share Settings | Secondary storage | **None** |
| Share Settings | Enable Copy-on-write | **Auto** |
| Share Settings | Allocation method | **High-water** |
| Share Settings | Split level | Automatically split any directory as required |
| Share Settings | Included disk(s) | **disk1** |
| Share Settings | Excluded disk(s) | blank |
| SMB Security Settings | Export | **Yes** (or **No** until chapter `15`) |
| SMB Security Settings | Time Machine volume size limit | blank |
| SMB Security Settings | Case-sensitive names | **Auto** |
| SMB Security Settings | Security | **Private** |

#### `media`

| Section | Field | Value |
|---|---|---|
| Share Settings | Share name | `media` |
| Share Settings | Comments | Jellyfin media libraries |
| Share Settings | Minimum free space | `100G` |
| Share Settings | Primary storage | **Array** |
| Share Settings | Secondary storage | **None** |
| Share Settings | Enable Copy-on-write | **Auto** |
| Share Settings | Allocation method | **High-water** |
| Share Settings | Split level | Automatically split any directory as required |
| Share Settings | Included disk(s) | **disk1** |
| Share Settings | Excluded disk(s) | blank |
| SMB Security Settings | Export | **Yes** (or **No** until chapter `15`) |
| SMB Security Settings | Time Machine volume size limit | blank |
| SMB Security Settings | Case-sensitive names | **Auto** |
| SMB Security Settings | Security | **Private** |

#### `backups-incoming`

| Section | Field | Value |
|---|---|---|
| Share Settings | Share name | `backups-incoming` |
| Share Settings | Comments | Incoming backups from PCs |
| Share Settings | Minimum free space | `50G` |
| Share Settings | Primary storage | **Array** |
| Share Settings | Secondary storage | **None** |
| Share Settings | Enable Copy-on-write | **Auto** |
| Share Settings | Allocation method | **High-water** |
| Share Settings | Split level | Automatically split any directory as required |
| Share Settings | Included disk(s) | **disk1** |
| Share Settings | Excluded disk(s) | blank |
| SMB Security Settings | Export | **Yes** (or **No** until chapter `15`) |
| SMB Security Settings | Time Machine volume size limit | blank |
| SMB Security Settings | Case-sensitive names | **Auto** |
| SMB Security Settings | Security | **Private** |

#### `public` (optional)

| Section | Field | Value |
|---|---|---|
| Share Settings | Share name | `public` |
| Share Settings | Comments | Temporary transfer folder |
| Share Settings | Minimum free space | `10G` |
| Share Settings | Primary storage | **Array** |
| Share Settings | Secondary storage | **None** |
| Share Settings | Enable Copy-on-write | **Auto** |
| Share Settings | Allocation method | **High-water** |
| Share Settings | Split level | Automatically split any directory as required |
| Share Settings | Included disk(s) | **disk1** |
| Share Settings | Excluded disk(s) | blank |
| SMB Security Settings | Export | **Yes** |
| SMB Security Settings | Time Machine volume size limit | blank |
| SMB Security Settings | Case-sensitive names | **Auto** |
| SMB Security Settings | Security | **Secure** (preferred) or **Private** — avoid **Public** |

### Quick reference

| Share | Min free | Primary | CoW | Export | Case-sensitive | Security | TM size limit |
|---|---|---|---|---|---|---|---|
| `appdata` | `20G` | `cache` | Auto | **No** | Auto | — | blank |
| `system` | `10G` | `cache` | Auto | **No** | Auto | — | blank |
| `domains` | `50G` | `cache` | Auto | **No** | Auto | — | blank |
| `database-backups-staging` | `10G` | `cache` | Auto | **No** | Auto | — | blank |
| `photos` | `50G` | Array | Auto | **Yes** | Auto | **Private** | blank |
| `documents` | `20G` | Array | Auto | **Yes** | Auto | **Private** | blank |
| `media` | `100G` | Array | Auto | **Yes** | Auto | **Private** | blank |
| `backups-incoming` | `50G` | Array | Auto | **Yes** | Auto | **Private** | blank |
| `public` | `10G` | Array | Auto | **Yes** | Auto | **Secure** | blank |

Named SMB users (who gets Read/Write) are configured in chapter `15`. Click **Apply** after each share.

**Security modes (Unraid):**

| Security | Meaning |
|---|---|
| **Private** | Only users you grant access; best default for personal data |
| **Secure** | Guests can read; named users can write if granted |
| **Public** | No login; avoid on this build |

Do **not** set Export to **Yes (Time Machine)** on the shares above. If you want Mac Time Machine later, create a separate share (for example `timemachine`) with Export = **Yes (Time Machine)** and a Time Machine volume size limit.

You should now see paths like:

- `/mnt/user/appdata`
- `/mnt/user/photos`
- `/mnt/user/media`

## Step 5 — Exos backup disk (can wait)

When the Exos arrives:

1. Open **Apps** → install **Unassigned Devices** if missing (from chapter `03`).
2. Physically attach the Exos. Do **not** assign it under **Main → Array Devices**.
3. On **Main → Unassigned Devices**, select the Exos.
4. Format / mount only when needed for backup.
5. Suggested values:

| Field | Value |
|---|---|
| Mount point | `/mnt/disks/weekly_backup` |
| File system | **xfs** (or existing FS if already formatted) |
| Auto mount | **No** / off |
| Share (SMB export of the UD disk) | **No** (optional; prefer not) |

6. Confirm under **Settings → Unassigned Devices** that auto-mount at boot stays off.

Full weekly backup steps are in chapter `10` after apps exist.

## Step 6 — SMART / disk settings

1. Open **Settings → Disk Settings**.
2. Suggested starting values (adjust after you see real temps):

| Field | Suggested value |
|---|---|
| Default spin down delay | your preference (array HDD can spin down if idle policy allows) |
| Tunable (enable SMART) | enabled / default |
| Warning disk temperature threshold | `45`–`48` °C |
| Critical disk temperature threshold | `50`–`55` °C |

3. On **Main**, click **Disk 1** (IronWolf) for SMART self-tests:

| Disk | Short test | Extended test |
|---|---|---|
| IronWolf | Weekly | Monthly |
| Exos (when used) | Around weekly backup | Monthly in a maintenance window |

Watch reallocated, pending, and uncorrectable sectors. UDMA CRC errors often mean a cable issue.

## Done checklist

- [ ] GM7000 pool `cache` online on **Main**
- [ ] IronWolf is Disk 1, parity empty
- [ ] Array started
- [ ] All shares created with the field values above
- [ ] Pool shares show exclusive access where expected
- [ ] No apps installed yet

**Next:** chapter `05` Docker (enable the engine only).
