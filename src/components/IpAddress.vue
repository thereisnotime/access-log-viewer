<template>
  <span 
    class="ip-wrapper" 
    @contextmenu.prevent="showContextMenu"
    @click="showContextMenu"
    tabindex="0"
    @keyup.enter="showContextMenu"
  >
    <slot>{{ ip }}</slot>
    <ip-context-menu
      v-if="contextMenuOpen"
      :ip="ip"
      :show="contextMenuOpen"
      :x="x"
      :y="y"
      @close="closeContextMenu"
      @find-in-logs="findInLogs"
    />
  </span>
</template>

<script>
import IpContextMenu from './IpContextMenu.vue';

export default {
  name: 'IpAddress',
  components: {
    IpContextMenu
  },
  props: {
    ip: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      contextMenuOpen: false,
      x: 0,
      y: 0
    }
  },
  methods: {
    showContextMenu(e) {
      this.x = e.clientX;
      this.y = e.clientY;
      this.contextMenuOpen = true;
      e.preventDefault();
    },
    closeContextMenu() {
      this.contextMenuOpen = false;
    },
    findInLogs(ip) {
      this.$emit('find-in-logs', ip);
    }
  }
}
</script>

<style scoped>
.ip-wrapper {
  cursor: pointer;
  position: relative;
  border-bottom: 1px dotted rgba(128, 128, 128, 0.4);
  transition: color 0.2s, background-color 0.2s;
  padding: 2px 4px;
  border-radius: 3px;
}
.ip-wrapper:hover {
  text-decoration: underline;
  color: var(--v-secondary-base);
  background-color: rgba(139, 0, 0, 0.1);
}
</style> 