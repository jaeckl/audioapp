#include <jni.h>

#include <android/log.h>

#include <string>

#include "audioapp/bridge/BridgeHost.hpp"

#define LOG_TAG "audioapp_native"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

namespace {

audioapp::bridge::BridgeHost& bridge() {
    static audioapp::bridge::BridgeHost instance;
    return instance;
}

std::string jstringToUtf8(JNIEnv* env, jstring value) {
    if (value == nullptr) {
        return {};
    }
    const char* chars = env->GetStringUTFChars(value, nullptr);
    if (chars == nullptr) {
        return {};
    }
    std::string result(chars);
    env->ReleaseStringUTFChars(value, chars);
    return result;
}

} // namespace

extern "C" JNIEXPORT jstring JNICALL
Java_com_audioapp_daw_MainActivity_nativeInvoke(JNIEnv* env,
                                                jobject /*thiz*/,
                                                jstring method,
                                                jstring argsJson) {
    const auto methodName = jstringToUtf8(env, method);
    const auto args = jstringToUtf8(env, argsJson);
    const auto response = bridge().handleCommand(methodName, args);
    return env->NewStringUTF(response.c_str());
}

extern "C" JNIEXPORT void JNICALL
Java_com_audioapp_daw_MainActivity_nativePlay(JNIEnv* /*env*/, jobject /*thiz*/) {
    bridge().handleCommand("play", "");
}

extern "C" JNIEXPORT void JNICALL
Java_com_audioapp_daw_MainActivity_nativeStop(JNIEnv* /*env*/, jobject /*thiz*/) {
    bridge().handleCommand("stop", "");
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_audioapp_daw_MainActivity_nativeGetProjectFileJson(JNIEnv* env, jobject /*thiz*/) {
    // ADR-0006: serialize only; Kotlin ProjectArchiveStore writes zip bytes.
    const auto json = bridge().getProjectFileJson();
    return env->NewStringUTF(json.c_str());
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_audioapp_daw_MainActivity_nativeLoadProjectFileJson(JNIEnv* env,
                                                             jobject /*thiz*/,
                                                             jstring projectJson) {
    const auto json = jstringToUtf8(env, projectJson);
    const auto response = bridge().loadProjectFileJson(json);
    return env->NewStringUTF(response.c_str());
}
