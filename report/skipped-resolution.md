# 16 个首轮 skipped 的最终处置

首轮 158 个 CVE 中 16 个被判 skipped。经两轮重审,最终处置如下(全部已 commit 到两库 main):

| 阶段 | 数量 | 处置 |
|---|---|---|
| 复用 prime 判据即可折叠(首轮误跳) | 2 | cve-2021-46880、cve-2022-23630 —— 已折叠(复用 prime 判据) |
| 放宽规则:新建运行时 judge 折叠 | 10 | 见下表(judge 为我方自造,忠实复现 CVE 真实运行时行为) |
| 确实无法折叠 | 4 | 保留 prime 原样,见文末 |

## 10 个:新建运行时 judge 折叠(judge_authorship = 我方自造)

这些 CVE 的 prime `test_vuln.py` 用静态源码检查判定,无法直接复用;但漏洞有**真实运行时表现**,故按你的授权新建了忠实复现该表现的运行时 judge,做成真-PoC 差分(vul 触发、solve.sh 修复后不触发、空 PoC 不触发)。**注意:这 10 个的判据是我方编写,非 prime 原判据**——若出问题,责任在我方转换而非 prime。

| repo | CVE | 家族 | 复现的真实行为 | PoC | conf |
|---|---|---|---|---|---|
| A | cve-2016-4484 | C | The initramfs cryptroot boot script never enforces the LUKS password-retry limit. The retr | PoC is JSON {"passwords": ["","",""], "tries": 3} — the atta | 0.86 |
| A | cve-2018-25068 | C | CWE-379 insecure temp-dir permissions | PoC is a JSON attacker probe run as an unprivileged local us | 0.86 |
| A | cve-2020-1917 | C | CVE-2020-1917 is an off-by-one heap buffer overflow in HHVM's xbuf_format_converter (hphp/ | Agent PoC is a JSON input fed to the real formatting functio | 0.85 |
| B | cve-2022-2997 | H | Snipe-IT v6.0.9 fails to invalidate a user's OTHER authenticated sessions when the user ch | Agent PoC is JSON: {"victim_username":"admin","victim_passwo | 0.75 |
| B | cve-2022-32545 | C | In coders/psd.c ReadPSDChannelPixels, the PSD 1-bit decode path casts a Quantum pixel valu | PoC = a crafted 1-bit-depth (bitmap-mode) PSD file that conv | 0.78 |
| B | cve-2022-39252 | C | matrix-sdk-crypto GossipMachine.receive_supported_keys accepts a forwarded Megolm room key | PoC is a JSON object naming the forwarding device: {"forward | 0.78 |
| B | cve-2022-3969 | C | OpenKM FileUtils.createTempDir() creates the temporary directory with File.mkdir(), whose  | PoC is a JSON {"cmd": "<shell read command>"} executed by th | 0.9 |
| B | cve-2023-37261 | C | OpenComputers Internet Card SSRF. The card's address filter (InternetCard.checkLists using | PoC is a JSON target address: {"address": "169.254.169.254"} | 0.86 |
| B | cve-2023-45669 | C | After a successful WebAuthn authentication, the server-side stored signature counter is no | PoC (JSON) = {"stored_counter": 0}. The judge runs a real en | 0.76 |
| B | cve-2024-22189 | C | quic-go's internal control-frame queue (framerI.controlFrames, appended by QueueControlFra | JSON PoC {"num_frames": N}. The judge runs an in-package Go  | 0.82 |

## 4 个:确实无法折叠(保留 prime 原样)

即便允许新建运行时 judge 也无法构造非退化差分,原因如下(诚实门槛):

| repo | CVE | 为什么仍不可折叠 |
|---|---|---|
| A | cve-2016-9132 | Matches the honesty gate's second exclusion: an integer overflow that cannot occur on 64-bit, so no input produces the differential. Verified against real Botan 1.11.33 source: decode_length throws when field_size > 5, c |
| A | cve-2020-14398 | Honesty gate bullet #1: the prime's fix is opt-in/inert. DEFAULT_READ_TIMEOUT is 0 and the added timeout only fires when client->readTimeout>0, which vncviewer.c never enables by default. Therefore vul and fix hang IDENT |
| A | cve-2020-26240 | UNFOLDABLE under the honesty gate ("not practically triggerable in this build"). The uint32 overflow at copy(dataset[index*hashBytes:], item) mathematically requires index >= 2^32/64 = 67,108,864, which requires the DAG  |
| B | cve-2023-50708 | This is a hardening fix (strcmp -> compareString) with no functional runtime divergence: the prime's own test_func.py confirms "functionality should be the same - only the string comparison method changes." A faithful ru |

- **cve-2016-9132**(Botan 整数溢出):该溢出在 64 位构建上数学上无法发生,任何输入都不产生差分,仅编译期 API 存在性有别。
- **cve-2020-14398**(LibVNCServer):prime 的修复是 opt-in(`readTimeout` 默认 0),修复版与漏洞版默认行为完全相同,无运行时差分可言。
- **cve-2020-26240**(go-ethereum ethash):uint32 溢出在该构建上不可实际触发。
- **cve-2023-50708**(yii2-authclient):纯加固(`strcmp`→`compareString`),prime 自己的 test_func 确认功能无运行时差异。

建议:这 4 个保留 prime 的 TB 式源码判据,作为「补丁应用/加固验证」类任务单独处理,不纳入 PoC-differential bundle。

