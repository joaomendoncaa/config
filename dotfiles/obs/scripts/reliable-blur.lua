obs = obslua

source_name = "Video Capture Device (V4L2)"
filter_name = "Background Removal"
blur_amount = 10

MODEL = "models/SINet_Softmax_simple.with_runtime_opt.ort"
FILTER_ID = "background_removal"

local function tuned_settings()
    local s = obs.obs_data_create()
    obs.obs_data_set_bool(s, "advanced", true)
    obs.obs_data_set_bool(s, "stop_when_source_is_inactive", true)
    obs.obs_data_set_string(s, "model_select", MODEL)
    obs.obs_data_set_int(s, "numThreads", 2) -- ponytail: upstream says 2 beats 8 (less contention)
    obs.obs_data_set_int(s, "mask_every_x_frames", 3)
    obs.obs_data_set_int(s, "blur_background", blur_amount)
    obs.obs_data_set_bool(s, "enable_threshold", true)
    obs.obs_data_set_double(s, "threshold", 0.5)
    obs.obs_data_set_double(s, "contour_filter", 0.05)
    obs.obs_data_set_double(s, "smooth_contour", 0.5)
    obs.obs_data_set_double(s, "mask_expansion", 0.0)
    obs.obs_data_set_double(s, "feather", 0.4)
    obs.obs_data_set_double(s, "temporal_smooth_factor", 0.8)
    obs.obs_data_set_bool(s, "enable_image_similarity", false)
    obs.obs_data_set_double(s, "image_similarity_threshold", 100.0)
    obs.obs_data_set_bool(s, "enable_focal_blur", false)
    obs.obs_data_set_double(s, "blur_focus_point", 0.0)
    return s
end

local function with_source(fn)
    local src = obs.obs_get_source_by_name(source_name)
    if src == nil then
        return
    end
    fn(src)
    obs.obs_source_release(src)
end

-- Force-apply tuned settings + enable. Used on load and by the Apply button.
function apply_blur()
    with_source(function(src)
        local s = tuned_settings()
        local f = obs.obs_source_get_filter_by_name(src, filter_name)
        if f ~= nil then
            obs.obs_source_update(f, s)
            obs.obs_source_set_enabled(f, true)
            obs.obs_source_release(f)
        else
            f = obs.obs_source_create(FILTER_ID, filter_name, s, nil)
            if f ~= nil then
                obs.obs_source_filter_add(src, f)
                obs.obs_source_release(f)
            end
        end
        obs.obs_data_release(s)
    end)
end

-- Watchdog: only recreates the filter if it went missing. Never fights manual tweaks.
function watchdog()
    with_source(function(src)
        local f = obs.obs_source_get_filter_by_name(src, filter_name)
        if f == nil then
            local s = tuned_settings()
            local nf = obs.obs_source_create(FILTER_ID, filter_name, s, nil)
            if nf ~= nil then
                obs.obs_source_filter_add(src, nf)
                obs.obs_source_release(nf)
                obs.script_log(obs.LOG_INFO, "reliable-blur: recreated missing filter on " .. source_name)
            end
            obs.obs_data_release(s)
        else
            obs.obs_source_release(f)
        end
    end)
end

function apply_pressed(props, p)
    apply_blur()
    return false
end

function script_description()
    return "Reliable webcam background blur.\nOwns one '" .. filter_name .. "' filter on your webcam with tuned low-CPU settings (SINet, 2 threads, every 3rd frame). Recreates it if it goes missing."
end

function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_text(props, "source", "Webcam source name", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_int(props, "blur", "Blur amount", 1, 20, 1)
    obs.obs_properties_add_button(props, "apply", "Apply tuned blur now", apply_pressed)
    return props
end

function script_update(settings)
    source_name = obs.obs_data_get_string(settings, "source")
    if source_name == "" then
        source_name = "Video Capture Device (V4L2)"
    end
    blur_amount = obs.obs_data_get_int(settings, "blur")
    if blur_amount < 1 then
        blur_amount = 10
    end
    apply_blur()
end

function script_defaults(settings)
    obs.obs_data_set_default_string(settings, "source", "Video Capture Device (V4L2)")
    obs.obs_data_set_default_int(settings, "blur", 10)
end

function script_load(settings)
    obs.timer_add(watchdog, 30000)
end

function script_unload()
    obs.timer_remove(watchdog)
end
