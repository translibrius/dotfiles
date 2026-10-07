// wezhere: Explorer "Open WezTerm here", elevated, without the UAC popup.
//
//   explorer -> wezhere.exe <dir>          medium IL: poke the scheduled task with <dir> as $(Arg0)
//   task     -> wezhere.exe --launch <dir> high IL ("Run with highest privileges"): spawn wezterm in <dir>
//   explorer -> wezhere.exe --user <dir>   plain unelevated wezterm, for drag-drop (UIPI blocks
//                                          Explorer -> elevated window drops)
//
// Task Scheduler is the only stock way to get high IL without consent.exe. The elevated wezterm
// reads user-writable stuff (wezterm.lua, PS profile), so anything running as you can ride it to
// admin. That's UAC "off for me" with extra steps; it was never a security boundary anyway.
//
// Build: see build.sh. Install: install.ps1.

#define WIN32_LEAN_AND_MEAN
#define COBJMACROS
#include <windows.h>
#include <shellapi.h>
#include <taskschd.h>

#define TASK_NAME L"wezhere"

static void fail(const wchar_t *what, HRESULT hr)
{
    wchar_t msg[512];
    wsprintfW(msg, L"%s failed (0x%08X).\nRun install.ps1 again?", what, (unsigned)hr);
    MessageBoxW(NULL, msg, L"wezhere", MB_ICONERROR);
    ExitProcess(1);
}

// Everything after the first `skip` args of our own command line, raw. Explorer hands us
// "C:\" for drive roots, and CommandLineToArgvW turns `"C:\"` into `C:"` — so parse by hand.
static wchar_t *raw_tail(wchar_t *cmd, int skip)
{
    for (int i = 0; i < skip; i++) {
        while (*cmd == L' ') cmd++;
        if (*cmd == L'"') { cmd++; while (*cmd && *cmd != L'"') cmd++; if (*cmd) cmd++; }
        else while (*cmd && *cmd != L' ') cmd++;
    }
    while (*cmd == L' ') cmd++;
    if (*cmd == L'"') {
        cmd++;
        wchar_t *end = cmd + lstrlenW(cmd);
        while (end > cmd && (end[-1] == L'"' || end[-1] == L' ')) end--;
        *end = 0;
    }
    return cmd;
}

static void spawn_wezterm(const wchar_t *dir)
{
    wchar_t exe[MAX_PATH];
    ExpandEnvironmentStringsW(L"%USERPROFILE%\\scoop\\apps\\wezterm-nightly\\current\\wezterm-gui.exe", exe, MAX_PATH);
    if (GetFileAttributesW(exe) == INVALID_FILE_ATTRIBUTES &&
        !SearchPathW(NULL, L"wezterm-gui.exe", NULL, MAX_PATH, exe, NULL))
        fail(L"finding wezterm-gui.exe", HRESULT_FROM_WIN32(GetLastError()));

    // --always-new-process: otherwise it hands the window to an already running unelevated
    // wezterm-gui and you get a normal-IL tab. Trailing backslash doubled so `"C:\"` doesn't
    // eat the closing quote (MSVC argv rules: 2n backslashes + quote -> n backslashes).
    int n = lstrlenW(dir);
    int trailing = (n > 0 && dir[n - 1] == L'\\');
    wchar_t cmd[2 * MAX_PATH + 128];
    wsprintfW(cmd, L"\"%s\" start --always-new-process --cwd \"%s%s\"", exe, dir, trailing ? L"\\" : L"");

    STARTUPINFOW si = {0};
    si.cb = sizeof si;
    PROCESS_INFORMATION pi;
    // Breakaway: the task's job object may get torn down when this process exits.
    DWORD flags = CREATE_BREAKAWAY_FROM_JOB;
    if (!CreateProcessW(exe, cmd, NULL, NULL, FALSE, flags, NULL, n ? dir : NULL, &si, &pi) &&
        !CreateProcessW(exe, cmd, NULL, NULL, FALSE, 0, NULL, n ? dir : NULL, &si, &pi))
        fail(L"starting wezterm", HRESULT_FROM_WIN32(GetLastError()));
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
}

static void run_task(const wchar_t *dir)
{
    HRESULT hr = CoInitializeEx(NULL, COINIT_MULTITHREADED);
    if (FAILED(hr)) fail(L"CoInitializeEx", hr);

    ITaskService *svc;
    hr = CoCreateInstance(&CLSID_TaskScheduler, NULL, CLSCTX_INPROC_SERVER, &IID_ITaskService, (void **)&svc);
    if (FAILED(hr)) fail(L"CoCreateInstance(TaskScheduler)", hr);

    VARIANT empty; VariantInit(&empty);
    hr = ITaskService_Connect(svc, empty, empty, empty, empty);
    if (FAILED(hr)) fail(L"ITaskService::Connect", hr);

    ITaskFolder *root;
    BSTR root_name = SysAllocString(L"\\");
    hr = ITaskService_GetFolder(svc, root_name, &root);
    if (FAILED(hr)) fail(L"GetFolder", hr);

    IRegisteredTask *task;
    BSTR task_name = SysAllocString(TASK_NAME);
    hr = ITaskFolder_GetTask(root, task_name, &task);
    if (FAILED(hr)) fail(L"finding the 'wezhere' task", hr);

    // A single BSTR param becomes $(Arg0) in the action's arguments.
    VARIANT params; VariantInit(&params);
    params.vt = VT_BSTR;
    params.bstrVal = SysAllocString(dir);
    IRunningTask *running = NULL;
    hr = IRegisteredTask_Run(task, params, &running);
    if (FAILED(hr)) fail(L"running the 'wezhere' task", hr);
    // No cleanup: process exits next line, the kernel is a better free() than me.
}

int WINAPI wWinMain(HINSTANCE inst, HINSTANCE prev, PWSTR args, int show)
{
    (void)inst; (void)prev; (void)args; (void)show;
    wchar_t *cmd = GetCommandLineW();

    int argc;
    wchar_t **argv = CommandLineToArgvW(cmd, &argc);
    if (argc >= 2 && lstrcmpW(argv[1], L"--launch") == 0) spawn_wezterm(raw_tail(cmd, 2));
    else if (argc >= 2 && lstrcmpW(argv[1], L"--user") == 0) spawn_wezterm(raw_tail(cmd, 2));
    else run_task(raw_tail(cmd, 1));
    return 0;
}
