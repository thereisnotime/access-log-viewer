<template>
  <span 
    class="ip-wrapper" 
    @contextmenu.prevent="showContextMenu"
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
    }
  }
}
</script>

<style scoped>
.ip-wrapper {
  cursor: context-menu;
  position: relative;
  border-bottom: 1px dotted rgba(128, 128, 128, 0.4);
}
.ip-wrapper:hover {
  text-decoration: underline;
  color: var(--v-secondary-base);
}
</style> 