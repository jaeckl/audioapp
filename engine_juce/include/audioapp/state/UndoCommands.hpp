#pragma once

#include <juce_core/juce_core.h>

#include <string>

namespace audioapp {

/// Undoable action for a simple set-and-restore mutation.
/// Stores old and new values, calls a restore function on undo/redo.
class SetPropertyAction : public juce::UndoableAction {
public:
    using RestoreFn = std::function<void(const juce::var& value)>;

    SetPropertyAction(RestoreFn restoreFn,
                      juce::var oldValue,
                      juce::var newValue)
        : restoreFn_(std::move(restoreFn)),
          oldValue_(std::move(oldValue)),
          newValue_(std::move(newValue)) {}

    bool perform() override {
        restoreFn_(newValue_);
        return true;
    }

    bool undo() override {
        restoreFn_(oldValue_);
        return true;
    }

    int getSizeInUnits() override { return 1; }

private:
    RestoreFn restoreFn_;
    juce::var oldValue_;
    juce::var newValue_;
};

/// Undoable action that wraps a pair of "perform" / "undo" lambdas.
class CallbackAction : public juce::UndoableAction {
public:
    using Fn = std::function<void()>;

    CallbackAction(Fn performFn, Fn undoFn)
        : performFn_(std::move(performFn)), undoFn_(std::move(undoFn)) {}

    bool perform() override {
        performFn_();
        return true;
    }

    bool undo() override {
        undoFn_();
        return true;
    }

    int getSizeInUnits() override { return 1; }

private:
    Fn performFn_;
    Fn undoFn_;
};

} // namespace audioapp