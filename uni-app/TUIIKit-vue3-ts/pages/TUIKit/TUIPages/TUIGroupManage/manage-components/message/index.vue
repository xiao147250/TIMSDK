<template>
  <transition
    name="fade"
    @before-leave="onClose"
    @after-leave="$emit('destroy')"
  >
  <div class="message" :style="customStyle" v-show="visible">
    <p>{{message}}</p>
  </div>
  </transition>
</template>
<script lang="ts">
import { computed, CSSProperties, defineComponent, onMounted, ref, watch } from 'vue';
export default defineComponent({
  name: 'TUIMessage',
  props: {
    message: {
      type: String,
      default: '',
    },
    duration: {
      type: Number,
      default: 3000,
    },
    repeatNum: {
      type: Number,
      default: 1,
    },
    id: {
      type: String,
      default: '',
    },
    onClose: {
      type: Function,
      required: false,
    },
    offset: {
      type: Number,
      default: 20,
    },
    zIndex: {
      type: Number,
      default: 0,
    },
  },
  setup(props: any) {
    const visible = ref(false);

    let stopTimer: (() => void) | undefined = undefined;

    function startTimer() {
      if (props.duration > 0) {
      }
    }

    function clearTimer() {
      stopTimer?.();
    };

    function close() {
      visible.value = false;
    };

    watch(
      () => props.repeatNum,
      () => {
        clearTimer();
        startTimer();
      },
    );


    const customStyle = computed<CSSProperties>(() => ({
      top: `${props.offset}px`,
      zIndex: props.zIndex,
    }));

    onMounted(() => {
      startTimer();
      visible.value = true;
    });

    return {
      visible,
      customStyle,
    };
  },
});
</script>
<style lang="scss" scoped>
.message {
  position: fixed;
  left: 0;
  right: 0;
  margin: 0 auto;
  max-width: 450px;
  display: flex;
  justify-content: center;
  align-items: center;
  p {
    background: #FFFFFF;
    box-shadow: 0 2px 12px 0 rgb(0 0 0 / 20%);
    border-radius: 3px;
    padding: 5px 10px;
  }
}
</style>
