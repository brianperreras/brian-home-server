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

### How to read the Add Share form

| Field | What to do |
|---|---|
| Share name | Exact name below (lowercase, no spaces) |
| Comments | Short description (optional but recommended) |
| Minimum free space | Floor so a nearly full disk is not chosen for a huge write. Examples: `20G` for appdata, `50G`–`100G` for large media/photo shares. Leave blank only if you accept Unraid’s default. |
| Primary storage | Where new files are written first (`cache` or **Array**) |
| Secondary storage | Overflow / mover target. Use **None** for this build |
| Allocation method | Only appears when Primary or Secondary is **Array**. Use **High-water** |
| Split level | Only for Array shares. Use **Automatically split any directory as required** (or blank / Automatic) on a single-disk array |
| Included disk(s) | For Array shares: **disk1** (or All — only disk1 exists) |
| Excluded disk(s) | blank |
| Mover action | Hidden / irrelevant when Secondary = **None** |

With only Disk 1 in the array, allocation method and split level barely matter, but set them so the form is complete.

### Pool shares (Primary = `cache`, Secondary = None)

Create each of these. After creation, open the share and confirm **Exclusive access** shows **Yes** (needs Step 3).

#### `appdata`

| Field | Value |
|---|---|
| Share name | `appdata` |
| Comments | Docker configs and databases |
| Minimum free space | `20G` |
| Primary storage | `cache` |
| Secondary storage | **None** |
| Allocation / Split / Include | not used (pool-only) |

#### `system`

| Field | Value |
|---|---|
| Share name | `system` |
| Comments | Docker system data |
| Minimum free space | `10G` |
| Primary storage | `cache` |
| Secondary storage | **None** |

#### `domains` (optional)

| Field | Value |
|---|---|
| Share name | `domains` |
| Comments | Future VMs |
| Minimum free space | `50G` |
| Primary storage | `cache` |
| Secondary storage | **None** |

#### `database-backups-staging`

| Field | Value |
|---|---|
| Share name | `database-backups-staging` |
| Comments | Temporary DB dumps before weekly backup |
| Minimum free space | `10G` |
| Primary storage | `cache` |
| Secondary storage | **None** |

### Array shares (Primary = Array, Secondary = None)

Do **not** set Primary to `cache` for these. Large libraries stay on the IronWolf.

#### `photos`

| Field | Value |
|---|---|
| Share name | `photos` |
| Comments | Immich photo library |
| Minimum free space | `50G` |
| Primary storage | **Array** |
| Secondary storage | **None** |
| Allocation method | **High-water** |
| Split level | Automatically split any directory as required |
| Included disk(s) | **disk1** |
| Excluded disk(s) | blank |

#### `documents`

| Field | Value |
|---|---|
| Share name | `documents` |
| Comments | Personal documents |
| Minimum free space | `20G` |
| Primary storage | **Array** |
| Secondary storage | **None** |
| Allocation method | **High-water** |
| Split level | Automatically split any directory as required |
| Included disk(s) | **disk1** |
| Excluded disk(s) | blank |

#### `media`

| Field | Value |
|---|---|
| Share name | `media` |
| Comments | Jellyfin media libraries |
| Minimum free space | `100G` |
| Primary storage | **Array** |
| Secondary storage | **None** |
| Allocation method | **High-water** |
| Split level | Automatically split any directory as required |
| Included disk(s) | **disk1** |
| Excluded disk(s) | blank |

#### `backups-incoming`

| Field | Value |
|---|---|
| Share name | `backups-incoming` |
| Comments | Incoming backups from PCs |
| Minimum free space | `50G` |
| Primary storage | **Array** |
| Secondary storage | **None** |
| Allocation method | **High-water** |
| Split level | Automatically split any directory as required |
| Included disk(s) | **disk1** |
| Excluded disk(s) | blank |

#### `public` (optional)

| Field | Value |
|---|---|
| Share name | `public` |
| Comments | Temporary transfer folder |
| Minimum free space | `10G` |
| Primary storage | **Array** |
| Secondary storage | **None** |
| Allocation method | **High-water** |
| Split level | Automatically split any directory as required |
| Included disk(s) | **disk1** |
| Excluded disk(s) | blank |

### Quick reference

| Share | Comments | Min free | Primary | Secondary |
|---|---|---|---|---|
| `appdata` | Docker configs and databases | `20G` | `cache` | None |
| `system` | Docker system data | `10G` | `cache` | None |
| `domains` | Future VMs | `50G` | `cache` | None |
| `database-backups-staging` | Temp DB dumps | `10G` | `cache` | None |
| `photos` | Immich library | `50G` | Array | None |
| `documents` | Personal documents | `20G` | Array | None |
| `media` | Jellyfin libraries | `100G` | Array | None |
| `backups-incoming` | PC backups | `50G` | Array | None |
| `public` | Transfer folder | `10G` | Array | None |

### SMB on each share (basic for now)

After creating a share, open it from **Shares** and set **SMB Security Settings**:

| Share | Export | Security |
|---|---|---|
| `appdata` | **No** | — |
| `system` | **No** | — |
| `domains` | **No** | — |
| `database-backups-staging` | **No** | — |
| `photos` | **Yes** (or No until chapter `15`) | **Private** |
| `documents` | **Yes** (or No until chapter `15`) | **Private** |
| `media` | **Yes** (or No until chapter `15`) | **Private** |
| `backups-incoming` | **Yes** (or No until chapter `15`) | **Private** |
| `public` | **Yes** (optional) | **Secure** or **Private** |

Named SMB users are configured in chapter `15`. Click **Apply** after each share.

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
