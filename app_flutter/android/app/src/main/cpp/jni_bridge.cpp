#include <jni.h>

#include <android/log.h>

#include <string>
#include <vector>

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

std::vector<uint8_t> jbyteArrayToVector(JNIEnv* env, jbyteArray array) {
    if (array == nullptr) {
        return {};
    }
    const auto length = env->GetArrayLength(array);
    if (length <= 0) {
        return {};
    }
    std::vector<uint8_t> bytes(static_cast<size_t>(length));
    env->GetByteArrayRegion(array, 0, length, reinterpret_cast<jbyte*>(bytes.data()));
    return bytes;
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

extern "C" JNIEXPORT jstring JNICALL
Java_com_audioapp_daw_MainActivity_nativeImportWavSample(JNIEnv* env,
                                                         jobject /*thiz*/,
                                                         jstring displayName,
                                                         jbyteArray wavBytes) {
    const auto name = jstringToUtf8(env, displayName);
    const auto bytes = jbyteArrayToVector(env, wavBytes);
    const auto response = bridge().importWavSample(name, bytes);
    return env->NewStringUTF(response.c_str());
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_audioapp_daw_MainActivity_nativeLoadWavetableAsset(JNIEnv* env,
                                                            jobject /*thiz*/,
                                                            jstring name,
                                                            jbyteArray wavBytes) {
    const auto nameStr = jstringToUtf8(env, name);
    const auto bytes = jbyteArrayToVector(env, wavBytes);
    const auto result = bridge().loadWavetableAsset(nameStr, bytes);
    return result ? JNI_TRUE : JNI_FALSE;
}

extern "C" JNIEXPORT jfloatArray JNICALL
Java_com_audioapp_daw_MainActivity_nativeRenderOffline(JNIEnv* env,
                                                       jobject /*thiz*/,
                                                       jdouble lengthBeats) {
    const auto pcm = bridge().renderOffline(lengthBeats, 48000.0);
    if (pcm.empty()) {
        return env->NewFloatArray(0);
    }
    jfloatArray array = env->NewFloatArray(static_cast<jsize>(pcm.size()));
    if (array == nullptr) {
        return nullptr;
    }
    env->SetFloatArrayRegion(array, 0, static_cast<jsize>(pcm.size()), pcm.data());
    return array;
}
