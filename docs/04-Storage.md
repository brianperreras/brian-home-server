# 04 - Storage Layout

Do this chapter **before** Docker and before any app (Immich, Home Assistant, Jellyfin). Steps match **Unraid 7.3.2** WebGUI labels.

Goal: assign disks, create empty shares, start the array. Do **not** install apps here.

This build uses the SSD pool named **`cache`** (Unraid default). Primary storage for appdata/system shares is **`cache`**, not Array.

## Devices

| Device | Role | Availability |
|---|---|---|
| Acer Predator GM7000 1 TB | SSD pool (`cache`) for appdata and databases | 24/7 |
| Seagate IronWolf 6 TB | Array disk 1 (no parity); final home for photos (via mover), documents, media, downloads | 24/7 |
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
2. Under the **POOLS** section on **Main**, click **Add Pool** (or fill the empty pool slot).
3. Fill:

| Field | Value |
|---|---|
| Pool name | `cache` |
| Slots / device | Acer Predator GM7000 (match by serial) |
| File system | **xfs** (simple single-drive pool) |
| Partition format | GPT / Unraid default |

4. Do not start the array yet if the IronWolf is not assigned — finish Step 2 first.

## Step 2 — Assign the IronWolf

1. Still on **Main** in the **ARRAY DEVICES** section.
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
2. Switch to **Advanced View** (top-right) if the page has that toggle.
3. Fill:

| Field | Value |
|---|---|
| Enable user shares | **Yes** |
| Permit exclusive shares | **Yes** |
| Included disk(s) (global) | leave default / all (unless you have a reason to restrict) |
| Excluded disk(s) (global) | blank |

4. Click **Apply**.

Exclusive access keeps `appdata` / `system` on the SSD pool without FUSE overhead when Primary is the pool and Secondary is None.

## Step 4 — Create shares (folders only)

You can use the WebGUI (below) **or** create/update all handbook shares in one shot from the Unraid terminal.

### Optional — User Scripts (copy/paste, no repo on server)

Array must be **started**. Paste each script **in full** into User Scripts — nothing else to install on the flash.

1. Open **Settings → User Scripts → Add New Script**.
2. Create two scripts (**Run manually**, no cron):

| Script name | Paste from this repo |
|---|---|
| `create-shares` | entire [`scripts/create-shares.sh`](../scripts/create-shares.sh) |
| `validate-shares` | entire [`scripts/validate-shares.sh`](../scripts/validate-shares.sh) |

3. In each script: gear → **Edit Script** → select all → paste → **Save**.
4. Run order:
   1. **`create-shares` → Run Script** (overwrites share `.cfg` with handbook values; backs up old `.cfg` first)
   2. **Main → Stop Array → Start Array**
   3. **`validate-shares` → Run Script** (look for `RESULT: OK`)
   4. Spot-check **Shares** → `photos`: Primary=`cache`, Secondary=**Array**, Mover=`cache→array`

These scripts are self-contained (no `share-defs` file). Named SMB users still come from chapter `15`.

### WebGUI (one share at a time)

1. Open **Shares**.
2. Click **Add Share**.
3. On the Add Share / share edit page, switch to **Advanced View** (top-right).
4. Fill the fields for each share using the templates below.
5. Click **Add Share** (or **Apply** when editing).
6. Repeat until every share in the lists exists.
7. Leave shares empty. Apps fill them later.

### Unraid 7.3.2 — which share fields you will actually see

| Field | When it appears |
|---|---|
| Share name, Comments, Minimum free space | Always |
| Primary storage / Secondary storage | Always |
| Enable Copy-on-write | **Only if the target filesystem is Btrfs**, and usually only while **adding** a new share. With **xfs** on `cache` and Disk 1 (this build), **you will not see this field** — skip it |
| Allocation method, Split level, Included / Excluded disk(s) | Only when Primary or Secondary is **Array** |
| Mover action | Only when Secondary is **not** None |
| SMB Security Settings (Export, Security, …) | Bottom of the share page. Use **Advanced View**. Some Time Machine fields appear only when Export is **Yes (Time Machine)** and/or macOS SMB options are enabled under **Settings → SMB** |

Toggle **Help** (?) top-right if a label is unclear.

### How to read the share forms

Fill **Share Settings**, then scroll to **SMB Security Settings**.

#### Share Settings (7.3.2)

| Field | What to do on this build |
|---|---|
| Share name | Exact name below (lowercase, no spaces) |
| Comments | Short description |
| Minimum free space | e.g. `20G` / `50G` / `100G` as listed per share |
| Primary storage | `cache` for pool-only shares and for `photos`; **Array** for other data shares |
| Secondary storage | **None** for pool-only and most array shares; **Array** for `photos` (mover) |
| Mover action | Only when Secondary is set — for `photos` use **`cache→array`** |
| Enable Copy-on-write | **Skip** on xfs (field hidden). If you ever use Btrfs and see it: leave **Auto** |
| Allocation method | When Array is Primary or Secondary → **High-water** |
| Split level | When Array is Primary or Secondary → Automatically split any directory as required |
| Included disk(s) | When Array is involved → **disk1** |
| Excluded disk(s) | blank |

#### SMB Security Settings (7.3.2)

| Field | What to do on this build |
|---|---|
| Export | **No** for appdata/system/…; **Yes** for photos/documents/media/… |
| Time Machine volume size limit | Leave blank (not using TM on these shares) |
| Case-sensitive names | **Auto** (Advanced View; if missing, leave default) |
| Security | **Private** (even when Export = No). Avoid **Public** |

**Security modes:**

| Security | Meaning |
|---|---|
| **Private** | Only users you grant access |
| **Secure** | Guests read-only; named users can write |
| **Public** | No login — avoid |

### Pool shares (Primary = `cache`, Secondary = None)

These stay on the GM7000 only. **Never** set Secondary to **Array** for them (no mover) — Docker, databases, and `docker.img` must not land on the IronWolf.

Create each of these. After creation, open the share and confirm **Primary storage** / **Secondary storage** match the tables below.

#### `appdata`

| Section | Field | Value |
|---|---|---|
| Share Settings | Share name | `appdata` |
| Share Settings | Comments | Docker configs and databases |
| Share Settings | Minimum free space | `20G` |
| Share Settings | Primary storage | `cache` |
| Share Settings | Secondary storage | **None** |
| Share Settings | Enable Copy-on-write | n/a (hidden on xfs) |
| Share Settings | Allocation / Split / Include | not used (pool-only) |
| SMB Security Settings | Export | **No** |
| SMB Security Settings | Time Machine volume size limit | blank |
| SMB Security Settings | Case-sensitive names | **Auto** |
| SMB Security Settings | Security | **Private** (ignored while Export = No) |

#### `system`

| Section | Field | Value |
|---|---|---|
| Share Settings | Share name | `system` |
| Share Settings | Comments | Docker system data |
| Share Settings | Minimum free space | `10G` |
| Share Settings | Primary storage | `cache` |
| Share Settings | Secondary storage | **None** |
| Share Settings | Enable Copy-on-write | n/a (hidden on xfs) |
| SMB Security Settings | Export | **No** |
| SMB Security Settings | Time Machine volume size limit | blank |
| SMB Security Settings | Case-sensitive names | **Auto** |
| SMB Security Settings | Security | **Private** (ignored while Export = No) |

#### `domains` (optional)

| Section | Field | Value |
|---|---|---|
| Share Settings | Share name | `domains` |
| Share Settings | Comments | Future VMs |
| Share Settings | Minimum free space | `50G` |
| Share Settings | Primary storage | `cache` |
| Share Settings | Secondary storage | **None** |
| Share Settings | Enable Copy-on-write | n/a (hidden on xfs) |
| SMB Security Settings | Export | **No** |
| SMB Security Settings | Time Machine volume size limit | blank |
| SMB Security Settings | Case-sensitive names | **Auto** |
| SMB Security Settings | Security | **Private** (ignored while Export = No) |

#### `database-backups-staging`

| Section | Field | Value |
|---|---|---|
| Share Settings | Share name | `database-backups-staging` |
| Share Settings | Comments | Temporary DB dumps before weekly backup |
| Share Settings | Minimum free space | `10G` |
| Share Settings | Primary storage | `cache` |
| Share Settings | Secondary storage | **None** |
| Share Settings | Enable Copy-on-write | n/a (hidden on xfs) |
| SMB Security Settings | Export | **No** |
| SMB Security Settings | Time Machine volume size limit | blank |
| SMB Security Settings | Case-sensitive names | **Auto** |
| SMB Security Settings | Security | **Private** (ignored while Export = No) |

### Cache-assisted share (`photos`: Primary = cache, Secondary = Array)

New Immich uploads land on the GM7000 (`cache`) first, then **mover** relocates them to the IronWolf (Array). Path stays `/mnt/user/photos/...` either way. **Minimum free space `50G`** is measured against the Primary (`cache`): when the SSD has less than ~50G free, new writes spill straight to the Array so Immich cannot fill the NVMe and starve `appdata` / Postgres.

#### `photos`

| Section | Field | Value |
|---|---|---|
| Share Settings | Share name | `photos` |
| Share Settings | Comments | Immich photo library (cache → array) |
| Share Settings | Minimum free space | `50G` |
| Share Settings | Primary storage | `cache` |
| Share Settings | Secondary storage | **Array** |
| Share Settings | Mover action | **`cache→array`** |
| Share Settings | Enable Copy-on-write | n/a (hidden on xfs) |
| Share Settings | Allocation method | **High-water** |
| Share Settings | Split level | Automatically split any directory as required |
| Share Settings | Included disk(s) | **disk1** |
| Share Settings | Excluded disk(s) | blank |
| SMB Security Settings | Export | **Yes** (or **No** until chapter `15`) |
| SMB Security Settings | Time Machine volume size limit | blank |
| SMB Security Settings | Case-sensitive names | **Auto** |
| SMB Security Settings | Security | **Private** |

Confirm mover schedule under **Settings → Scheduler → Mover settings** (daily off-peak is fine). Do not overlap mover with the weekly Exos backup (chapter `10`). Mover skips open files — for a full drain after a big import, stop Immich, run **Move Now**, then start Immich again.

### Array shares (Primary = Array, Secondary = None)

Do **not** set Primary to `cache` for these, and do **not** enable cache→array on `media`, `downloads`, `backups-incoming`, or `public`. The NVMe write cache is reserved for Immich (`photos`) plus pool-only appdata — large media, PC dumps, and downloads would fill or thrash the 1 TB SSD.

#### `documents`

| Section | Field | Value |
|---|---|---|
| Share Settings | Share name | `documents` |
| Share Settings | Comments | Personal documents |
| Share Settings | Minimum free space | `20G` |
| Share Settings | Primary storage | **Array** |
| Share Settings | Secondary storage | **None** |
| Share Settings | Enable Copy-on-write | n/a (hidden on xfs) |
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
| Share Settings | Enable Copy-on-write | n/a (hidden on xfs) |
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
| Share Settings | Enable Copy-on-write | n/a (hidden on xfs) |
| Share Settings | Allocation method | **High-water** |
| Share Settings | Split level | Automatically split any directory as required |
| Share Settings | Included disk(s) | **disk1** |
| Share Settings | Excluded disk(s) | blank |
| SMB Security Settings | Export | **Yes** (or **No** until chapter `15`) |
| SMB Security Settings | Time Machine volume size limit | blank |
| SMB Security Settings | Case-sensitive names | **Auto** |
| SMB Security Settings | Security | **Private** |

#### `downloads`

| Section | Field | Value |
|---|---|---|
| Share Settings | Share name | `downloads` |
| Share Settings | Comments | Browser / PC downloads and staging files |
| Share Settings | Minimum free space | `50G` |
| Share Settings | Primary storage | **Array** |
| Share Settings | Secondary storage | **None** |
| Share Settings | Enable Copy-on-write | n/a (hidden on xfs) |
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
| Share Settings | Enable Copy-on-write | n/a (hidden on xfs) |
| Share Settings | Allocation method | **High-water** |
| Share Settings | Split level | Automatically split any directory as required |
| Share Settings | Included disk(s) | **disk1** |
| Share Settings | Excluded disk(s) | blank |
| SMB Security Settings | Export | **Yes** |
| SMB Security Settings | Time Machine volume size limit | blank |
| SMB Security Settings | Case-sensitive names | **Auto** |
| SMB Security Settings | Security | **Secure** (preferred) or **Private** — avoid **Public** |

### Quick reference

| Share | Min free | Primary | Secondary | Mover | Export | Case-sensitive | Security |
|---|---|---|---|---|---|---|---|
| `appdata` | `20G` | `cache` | **None** | — | **No** | Auto | **Private** |
| `system` | `10G` | `cache` | **None** | — | **No** | Auto | **Private** |
| `domains` | `50G` | `cache` | **None** | — | **No** | Auto | **Private** |
| `database-backups-staging` | `10G` | `cache` | **None** | — | **No** | Auto | **Private** |
| `photos` | `50G` | `cache` | **Array** | **`cache→array`** | **Yes** | Auto | **Private** |
| `documents` | `20G` | Array | **None** | — | **Yes** | Auto | **Private** |
| `media` | `100G` | Array | **None** | — | **Yes** | Auto | **Private** |
| `backups-incoming` | `50G` | Array | **None** | — | **Yes** | Auto | **Private** |
| `downloads` | `50G` | Array | **None** | — | **Yes** | Auto | **Private** |
| `public` | `10G` | Array | **None** | — | **Yes** | Auto | **Secure** |

Named SMB users (who gets Read/Write) are configured in chapter `15`. Click **Apply** after each share.

Do **not** set Export to **Yes (Time Machine)** on the shares above. If you want Mac Time Machine later, create a separate share (for example `timemachine`) with Export = **Yes (Time Machine)** and a Time Machine volume size limit.

You should now see paths like:

- `/mnt/user/appdata`
- `/mnt/user/photos`
- `/mnt/user/media`
- `/mnt/user/downloads`

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

Unraid **7.3.2** has no field named **Tunable (enable SMART)**. SMART polling is always on unless you set the poll interval to `0`.

1. Open **Settings → Disk Settings**.
2. Suggested starting values (exact labels; adjust after you see real temps):

| Field (exact label) | Suggested value |
|---|---|
| Default spin down delay | your preference (set **Never** before an extended SMART test) |
| Tunable (poll_attributes) | leave default **1800** (seconds). Do **not** set `0` — that disables SMART polling |
| Default warning disk temperature threshold | `48` °C (HDDs) |
| Default critical disk temperature threshold | `52` °C (HDDs) |
| Default warning SSD temperature threshold | leave default (SATA SSDs; your GM7000 is NVMe) |
| Default critical SSD temperature threshold | leave default |
| Default SMART notification value | leave default (**Raw**) |
| Default SMART notification tolerance level | leave default |
| Default SMART controller type | **Automatic** |
| Default SMART attribute notifications | leave defaults checked (`5`, `187`, `197`, `198`, `199`) |

3. Optional per-disk overrides: **Main → Disk 1** (IronWolf) → **Settings** → **SMART Settings**. Blank thresholds inherit the globals above. For the GM7000 pool disk, the same page shows **NVME temperature** fields — leave blank or set warning ~`75` °C.

4. Self-tests are **manual** (Unraid has no built-in weekly/monthly SMART schedule). Open **Main → Disk 1 → Self-Test**:

| Disk | Short test | Extended test |
|---|---|---|
| IronWolf | Weekly (click **SMART short self-test → Start**) | Monthly (spin-down **Never** while it runs) |
| Exos (when used) | Around weekly backup from the Unassigned Devices disk page → **Self-Test** | Monthly in a maintenance window |

Watch reallocated, pending, and uncorrectable sectors. UDMA CRC errors often mean a cable issue.

## Done checklist

- [ ] GM7000 pool `cache` online on **Main**
- [ ] IronWolf is Disk 1, parity empty
- [ ] Array started
- [ ] All shares created with the field values above
- [ ] Pool shares show Primary storage: cache and Secondary storage: None
- [ ] Share `photos` shows Primary: cache, Secondary: Array, Mover: cache→array
- [ ] No apps installed yet

## Verify your setup

1. **NVMe pool `cache` online** — Main tab → POOLS section.
   Expected result: pool named `cache` shows the GM7000 device with status `Started` or `Online`.

2. **IronWolf assigned as Disk 1, parity empty** — Main tab → ARRAY DEVICES.
   Expected result: Disk 1 shows the Seagate IronWolf 6 TB (match serial); Parity slot is empty.

3. **Array started successfully** — Main tab → Array status.
   Expected result: Array status shows `Started` (with the expected `ARRAY UNPROTECTED` banner — that is normal for this no-parity design).

4. **Share `appdata` exists on NVMe pool** — Shares tab → appdata.
   Expected result: Primary storage = `cache`, Secondary storage = `None`.

5. **Share `photos` uses cache → array** — Shares tab → photos.
   Expected result: Primary storage = `cache`, Secondary storage = `Array`, Mover action = `cache→array`, Included disk = `disk1`.

6. **Shares `documents` and `media` exist** — Shares tab.
   Expected result: both appear with Primary = `Array`, disk1, Secondary = `None`.

7. **Share `database-backups-staging` exists on NVMe pool** — Shares tab.
   Expected result: Primary storage = `cache`, Secondary storage = `None`.

8. **NVMe free space visible** — open the Unraid terminal (>_) and run:

   ```bash
   df -h /mnt/user/appdata
   ```

   Expected result: filesystem shows ~1 TB available from the GM7000 (no IronWolf path).

9. **IronWolf free space visible** — open the Unraid terminal (>_) and run:

   ```bash
   df -h /mnt/user/photos
   ```

   Expected result: filesystem shows ~6 TB available from the IronWolf (Disk 1).

**Next:** chapter `05` Docker (enable the engine only).
