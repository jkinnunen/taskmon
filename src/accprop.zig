// Accessible properties a plain Win32 control has no way to carry on its own,
// attached through oleacc's dynamic annotation service (IAccPropServices).
// Screen readers pick them up through MSAA, and through the MSAA proxy for UIA.
const win32 = @import("win32.zig");

const CLSID_AccPropServices = win32.GUID{ .Data1 = 0xb5f8350b, .Data2 = 0x0548, .Data3 = 0x48b1, .Data4 = .{ 0xa6, 0xee, 0x88, 0xbd, 0x00, 0xb4, 0xa5, 0xe7 } };
const IID_IAccPropServices = win32.GUID{ .Data1 = 0x6e26e776, .Data2 = 0x04f0, .Data3 = 0x495d, .Data4 = .{ 0x80, 0xe4, 0x33, 0x30, 0x35, 0x2e, 0x31, 0x69 } };
const PROPID_ACC_DESCRIPTION = win32.GUID{ .Data1 = 0x4d48dfe4, .Data2 = 0xbd3f, .Data3 = 0x491f, .Data4 = .{ 0xa6, 0x48, 0x49, 0x2d, 0x6f, 0x20, 0xc5, 0x88 } };

// Only the slots called below are typed; the rest just hold their place in
// the vtable, which follows the declaration order in oleacc.h.
const IAccPropServices = extern struct {
	vtbl: *const extern struct {
		QueryInterface: *const anyopaque,
		AddRef: *const anyopaque,
		Release: *const fn (*IAccPropServices) callconv(.c) u32,
		SetPropValue: *const anyopaque,
		SetPropServer: *const anyopaque,
		ClearProps: *const anyopaque,
		SetHwndProp: *const anyopaque,
		SetHwndPropStr: *const fn (*IAccPropServices, win32.HWND, win32.DWORD, win32.DWORD, win32.GUID, win32.LPCWSTR) callconv(.c) c_long,
		SetHwndPropServer: *const anyopaque,
		ClearHwndProps: *const fn (*IAccPropServices, win32.HWND, win32.DWORD, win32.DWORD, [*]const win32.GUID, c_int) callconv(.c) c_long,
	},
};

fn service() ?*IAccPropServices {
	var ptr: ?*anyopaque = null;
	if (win32.CoCreateInstance(&CLSID_AccPropServices, null, win32.CLSCTX_INPROC_SERVER, &IID_IAccPropServices, &ptr) < 0) return null;
	return @ptrCast(@alignCast(ptr orelse return null));
}

/// Gives the control an accessible description, which screen readers speak
/// after its name and role when it takes focus. Pair with clearDescription
/// before the window is destroyed.
pub fn setDescription(hwnd: win32.HWND, text: win32.LPCWSTR) void {
	const svc = service() orelse return;
	_ = svc.vtbl.SetHwndPropStr(svc, hwnd, win32.OBJID_CLIENT, win32.CHILDID_SELF, PROPID_ACC_DESCRIPTION, text);
	_ = svc.vtbl.Release(svc);
}

pub fn clearDescription(hwnd: win32.HWND) void {
	const svc = service() orelse return;
	const props = [_]win32.GUID{PROPID_ACC_DESCRIPTION};
	_ = svc.vtbl.ClearHwndProps(svc, hwnd, win32.OBJID_CLIENT, win32.CHILDID_SELF, &props, props.len);
	_ = svc.vtbl.Release(svc);
}
